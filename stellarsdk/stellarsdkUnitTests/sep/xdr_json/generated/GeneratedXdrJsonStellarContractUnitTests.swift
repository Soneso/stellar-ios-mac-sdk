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

final class GeneratedXdrJsonStellarContractUnitTests: XCTestCase {

    func test_ContractExecutableExternalRefXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ContractExecutableExternalRefXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ContractExecutableExternalRefXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ContractExecutableExternalRefXDR_roundTrip() throws {
        let original: ContractExecutableExternalRefXDR = ContractExecutableExternalRefXDR(executableOwner: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), tag: "test_string")
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractExecutableExternalRefXDR.fromXdrJson(json)
        let viaValue = try ContractExecutableExternalRefXDR.fromXdrJsonValue(tree)
        let viaTree = try ContractExecutableExternalRefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractExecutableExternalRefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractExecutableExternalRefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractExecutableExternalRefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractExecutableExternalRefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractExecutableExternalRefXDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractExecutableType_CONTRACT_EXECUTABLE_EXTERNAL_REF() throws {
        let value: ContractExecutableType = .externalRef
        XCTAssertEqual(try value.toXdrJson(), "\"external_ref\"",
                       "ContractExecutableType.externalRef must render as external_ref")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "ContractExecutableType.externalRef must keep its XDR value")
        XCTAssertEqual(try ContractExecutableType.fromXdrJson("\"external_ref\""), value,
                       "external_ref must read back as ContractExecutableType.externalRef")
    }

    func test_ContractExecutableType_CONTRACT_EXECUTABLE_STELLAR_ASSET() throws {
        let value: ContractExecutableType = .stellarAsset
        XCTAssertEqual(try value.toXdrJson(), "\"stellar_asset\"",
                       "ContractExecutableType.stellarAsset must render as stellar_asset")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "ContractExecutableType.stellarAsset must keep its XDR value")
        XCTAssertEqual(try ContractExecutableType.fromXdrJson("\"stellar_asset\""), value,
                       "stellar_asset must read back as ContractExecutableType.stellarAsset")
    }

    func test_ContractExecutableType_CONTRACT_EXECUTABLE_WASM() throws {
        let value: ContractExecutableType = .wasm
        XCTAssertEqual(try value.toXdrJson(), "\"wasm\"",
                       "ContractExecutableType.wasm must render as wasm")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ContractExecutableType.wasm must keep its XDR value")
        XCTAssertEqual(try ContractExecutableType.fromXdrJson("\"wasm\""), value,
                       "wasm must read back as ContractExecutableType.wasm")
    }

    func test_ContractExecutableType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ContractExecutableType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ContractExecutableType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ContractExecutableType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ContractExecutableXDR_externalRef_rejectsBareString() throws {
        XCTAssertThrowsError(try ContractExecutableXDR.fromXdrJson("\"external_ref\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ContractExecutableXDR.external_ref: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ContractExecutableXDR")
            XCTAssertEqual(key, "external_ref",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ContractExecutableXDR_externalRef_roundTrip() throws {
        let original: ContractExecutableXDR = .externalRef(ContractExecutableExternalRefXDR(executableOwner: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), tag: "test_string"))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractExecutableXDR.fromXdrJson(json)
        let viaValue = try ContractExecutableXDR.fromXdrJsonValue(tree)
        let viaTree = try ContractExecutableXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractExecutableXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractExecutableXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractExecutableXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractExecutableXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractExecutableXDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractExecutableXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ContractExecutableXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ContractExecutableXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ContractExecutableXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ContractExecutableXDR_token_roundTrip() throws {
        let original: ContractExecutableXDR = .token
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractExecutableXDR.fromXdrJson(json)
        let viaValue = try ContractExecutableXDR.fromXdrJsonValue(tree)
        let viaTree = try ContractExecutableXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractExecutableXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractExecutableXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractExecutableXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractExecutableXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractExecutableXDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractExecutableXDR_wasm_rejectsBareString() throws {
        XCTAssertThrowsError(try ContractExecutableXDR.fromXdrJson("\"wasm\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ContractExecutableXDR.wasm: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ContractExecutableXDR")
            XCTAssertEqual(key, "wasm",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ContractExecutableXDR_wasm_roundTrip() throws {
        let original: ContractExecutableXDR = .wasm(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractExecutableXDR.fromXdrJson(json)
        let viaValue = try ContractExecutableXDR.fromXdrJsonValue(tree)
        let viaTree = try ContractExecutableXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractExecutableXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractExecutableXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractExecutableXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractExecutableXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractExecutableXDR must reach the same bytes through JSON and XDR")
    }

    func test_Int128PartsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try Int128PartsXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "Int128PartsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_Int128PartsXDR_roundTrip() throws {
        let original: Int128PartsXDR = Int128PartsXDR(hi: Int64(1234567), lo: UInt64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try Int128PartsXDR.fromXdrJson(json)
        let viaValue = try Int128PartsXDR.fromXdrJsonValue(tree)
        let viaTree = try Int128PartsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "Int128PartsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "Int128PartsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "Int128PartsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "Int128PartsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "Int128PartsXDR must reach the same bytes through JSON and XDR")
    }

    func test_Int256PartsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try Int256PartsXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "Int256PartsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_Int256PartsXDR_roundTrip() throws {
        let original: Int256PartsXDR = Int256PartsXDR(hiHi: Int64(1234567), hiLo: UInt64(1234567), loHi: UInt64(1234567), loLo: UInt64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try Int256PartsXDR.fromXdrJson(json)
        let viaValue = try Int256PartsXDR.fromXdrJsonValue(tree)
        let viaTree = try Int256PartsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "Int256PartsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "Int256PartsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "Int256PartsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "Int256PartsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "Int256PartsXDR must reach the same bytes through JSON and XDR")
    }

    func test_MuxedAccountMed25519XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try MuxedAccountMed25519XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "MuxedAccountMed25519XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_MuxedAccountMed25519XDR_roundTrip() throws {
        let original: MuxedAccountMed25519XDR = MuxedAccountMed25519XDR(id: UInt64(1), sourceAccountEd25519: [UInt8](repeating: 0xAB, count: 32))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try MuxedAccountMed25519XDR.fromXdrJson(json)
        let viaValue = try MuxedAccountMed25519XDR.fromXdrJsonValue(tree)
        let viaTree = try MuxedAccountMed25519XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "MuxedAccountMed25519XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "MuxedAccountMed25519XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "MuxedAccountMed25519XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "MuxedAccountMed25519XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "MuxedAccountMed25519XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCAddressType_SC_ADDRESS_TYPE_ACCOUNT() throws {
        let value: SCAddressType = .account
        XCTAssertEqual(try value.toXdrJson(), "\"account\"",
                       "SCAddressType.account must render as account")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SCAddressType.account must keep its XDR value")
        XCTAssertEqual(try SCAddressType.fromXdrJson("\"account\""), value,
                       "account must read back as SCAddressType.account")
    }

    func test_SCAddressType_SC_ADDRESS_TYPE_CLAIMABLE_BALANCE() throws {
        let value: SCAddressType = .claimableBalance
        XCTAssertEqual(try value.toXdrJson(), "\"claimable_balance\"",
                       "SCAddressType.claimableBalance must render as claimable_balance")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "SCAddressType.claimableBalance must keep its XDR value")
        XCTAssertEqual(try SCAddressType.fromXdrJson("\"claimable_balance\""), value,
                       "claimable_balance must read back as SCAddressType.claimableBalance")
    }

    func test_SCAddressType_SC_ADDRESS_TYPE_CONTRACT() throws {
        let value: SCAddressType = .contract
        XCTAssertEqual(try value.toXdrJson(), "\"contract\"",
                       "SCAddressType.contract must render as contract")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "SCAddressType.contract must keep its XDR value")
        XCTAssertEqual(try SCAddressType.fromXdrJson("\"contract\""), value,
                       "contract must read back as SCAddressType.contract")
    }

    func test_SCAddressType_SC_ADDRESS_TYPE_LIQUIDITY_POOL() throws {
        let value: SCAddressType = .liquidityPool
        XCTAssertEqual(try value.toXdrJson(), "\"liquidity_pool\"",
                       "SCAddressType.liquidityPool must render as liquidity_pool")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "SCAddressType.liquidityPool must keep its XDR value")
        XCTAssertEqual(try SCAddressType.fromXdrJson("\"liquidity_pool\""), value,
                       "liquidity_pool must read back as SCAddressType.liquidityPool")
    }

    func test_SCAddressType_SC_ADDRESS_TYPE_MUXED_ACCOUNT() throws {
        let value: SCAddressType = .muxedAccount
        XCTAssertEqual(try value.toXdrJson(), "\"muxed_account\"",
                       "SCAddressType.muxedAccount must render as muxed_account")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "SCAddressType.muxedAccount must keep its XDR value")
        XCTAssertEqual(try SCAddressType.fromXdrJson("\"muxed_account\""), value,
                       "muxed_account must read back as SCAddressType.muxedAccount")
    }

    func test_SCAddressType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SCAddressType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SCAddressType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SCAddressType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SCAddressXDR_account_roundTrip() throws {
        let original: SCAddressXDR = .account(try PublicKey([UInt8](repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCAddressXDR.fromXdrJson(json)
        let viaValue = try SCAddressXDR.fromXdrJsonValue(tree)
        let viaTree = try SCAddressXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCAddressXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCAddressXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCAddressXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCAddressXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCAddressXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCAddressXDR_claimableBalanceId_roundTrip() throws {
        let original: SCAddressXDR = .claimableBalanceId(.claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCAddressXDR.fromXdrJson(json)
        let viaValue = try SCAddressXDR.fromXdrJsonValue(tree)
        let viaTree = try SCAddressXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCAddressXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCAddressXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCAddressXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCAddressXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCAddressXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCAddressXDR_contract_roundTrip() throws {
        let original: SCAddressXDR = .contract(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCAddressXDR.fromXdrJson(json)
        let viaValue = try SCAddressXDR.fromXdrJsonValue(tree)
        let viaTree = try SCAddressXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCAddressXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCAddressXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCAddressXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCAddressXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCAddressXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCAddressXDR_liquidityPoolId_roundTrip() throws {
        let original: SCAddressXDR = .liquidityPoolId(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCAddressXDR.fromXdrJson(json)
        let viaValue = try SCAddressXDR.fromXdrJsonValue(tree)
        let viaTree = try SCAddressXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCAddressXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCAddressXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCAddressXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCAddressXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCAddressXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCAddressXDR_muxedAccount_roundTrip() throws {
        let original: SCAddressXDR = .muxedAccount(MuxedAccountMed25519XDR(id: UInt64(1), sourceAccountEd25519: [UInt8](repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCAddressXDR.fromXdrJson(json)
        let viaValue = try SCAddressXDR.fromXdrJsonValue(tree)
        let viaTree = try SCAddressXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCAddressXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCAddressXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCAddressXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCAddressXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCAddressXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCAddressXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCAddressXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCAddressXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCBytesXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCBytesXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCBytesXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCBytesXDR_roundTrip() throws {
        let original: SCBytesXDR = Data([0x01, 0x02, 0x03])
        let tree = try SCBytesXDRJsonCodec.toXdrJsonValue(original)
        let json = try SCBytesXDRJsonCodec.toXdrJson(original)
        let decoded = try SCBytesXDRJsonCodec.fromXdrJson(json)
        let viaValue = try SCBytesXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try SCBytesXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try SCBytesXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "SCBytesXDR must produce the same tree after a round trip")
        XCTAssertEqual(try SCBytesXDRJsonCodec.toXdrJson(decoded), json,
                       "SCBytesXDR must produce the same text after a round trip")
        XCTAssertEqual(try SCBytesXDRJsonCodec.toXdrJson(viaValue), json,
                       "SCBytesXDR must read a tree the same way it reads text")
        XCTAssertEqual(try SCBytesXDRJsonCodec.toXdrJson(viaTree), json,
                       "SCBytesXDR must read a depth-checked tree the same way")
    }

    func test_SCContractInstanceXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCContractInstanceXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCContractInstanceXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCContractInstanceXDR_roundTrip() throws {
        let original: SCContractInstanceXDR = SCContractInstanceXDR(executable: .token, storage: [SCMapEntryXDR(key: .void, val: .void)])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCContractInstanceXDR.fromXdrJson(json)
        let viaValue = try SCContractInstanceXDR.fromXdrJsonValue(tree)
        let viaTree = try SCContractInstanceXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCContractInstanceXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCContractInstanceXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCContractInstanceXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCContractInstanceXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCContractInstanceXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCErrorCode_SCEC_ARITH_DOMAIN() throws {
        let value: SCErrorCode = .arithDomain
        XCTAssertEqual(try value.toXdrJson(), "\"arith_domain\"",
                       "SCErrorCode.arithDomain must render as arith_domain")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SCErrorCode.arithDomain must keep its XDR value")
        XCTAssertEqual(try SCErrorCode.fromXdrJson("\"arith_domain\""), value,
                       "arith_domain must read back as SCErrorCode.arithDomain")
    }

    func test_SCErrorCode_SCEC_EXCEEDED_LIMIT() throws {
        let value: SCErrorCode = .exceededLimit
        XCTAssertEqual(try value.toXdrJson(), "\"exceeded_limit\"",
                       "SCErrorCode.exceededLimit must render as exceeded_limit")
        XCTAssertEqual(value.rawValue, Int32(5),
                       "SCErrorCode.exceededLimit must keep its XDR value")
        XCTAssertEqual(try SCErrorCode.fromXdrJson("\"exceeded_limit\""), value,
                       "exceeded_limit must read back as SCErrorCode.exceededLimit")
    }

    func test_SCErrorCode_SCEC_EXISTING_VALUE() throws {
        let value: SCErrorCode = .existingValue
        XCTAssertEqual(try value.toXdrJson(), "\"existing_value\"",
                       "SCErrorCode.existingValue must render as existing_value")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "SCErrorCode.existingValue must keep its XDR value")
        XCTAssertEqual(try SCErrorCode.fromXdrJson("\"existing_value\""), value,
                       "existing_value must read back as SCErrorCode.existingValue")
    }

    func test_SCErrorCode_SCEC_INDEX_BOUNDS() throws {
        let value: SCErrorCode = .indexBounds
        XCTAssertEqual(try value.toXdrJson(), "\"index_bounds\"",
                       "SCErrorCode.indexBounds must render as index_bounds")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "SCErrorCode.indexBounds must keep its XDR value")
        XCTAssertEqual(try SCErrorCode.fromXdrJson("\"index_bounds\""), value,
                       "index_bounds must read back as SCErrorCode.indexBounds")
    }

    func test_SCErrorCode_SCEC_INTERNAL_ERROR() throws {
        let value: SCErrorCode = .internalError
        XCTAssertEqual(try value.toXdrJson(), "\"internal_error\"",
                       "SCErrorCode.internalError must render as internal_error")
        XCTAssertEqual(value.rawValue, Int32(7),
                       "SCErrorCode.internalError must keep its XDR value")
        XCTAssertEqual(try SCErrorCode.fromXdrJson("\"internal_error\""), value,
                       "internal_error must read back as SCErrorCode.internalError")
    }

    func test_SCErrorCode_SCEC_INVALID_ACTION() throws {
        let value: SCErrorCode = .invalidAction
        XCTAssertEqual(try value.toXdrJson(), "\"invalid_action\"",
                       "SCErrorCode.invalidAction must render as invalid_action")
        XCTAssertEqual(value.rawValue, Int32(6),
                       "SCErrorCode.invalidAction must keep its XDR value")
        XCTAssertEqual(try SCErrorCode.fromXdrJson("\"invalid_action\""), value,
                       "invalid_action must read back as SCErrorCode.invalidAction")
    }

    func test_SCErrorCode_SCEC_INVALID_INPUT() throws {
        let value: SCErrorCode = .invalidInput
        XCTAssertEqual(try value.toXdrJson(), "\"invalid_input\"",
                       "SCErrorCode.invalidInput must render as invalid_input")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "SCErrorCode.invalidInput must keep its XDR value")
        XCTAssertEqual(try SCErrorCode.fromXdrJson("\"invalid_input\""), value,
                       "invalid_input must read back as SCErrorCode.invalidInput")
    }

    func test_SCErrorCode_SCEC_MISSING_VALUE() throws {
        let value: SCErrorCode = .missingValue
        XCTAssertEqual(try value.toXdrJson(), "\"missing_value\"",
                       "SCErrorCode.missingValue must render as missing_value")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "SCErrorCode.missingValue must keep its XDR value")
        XCTAssertEqual(try SCErrorCode.fromXdrJson("\"missing_value\""), value,
                       "missing_value must read back as SCErrorCode.missingValue")
    }

    func test_SCErrorCode_SCEC_UNEXPECTED_SIZE() throws {
        let value: SCErrorCode = .unexpectedSize
        XCTAssertEqual(try value.toXdrJson(), "\"unexpected_size\"",
                       "SCErrorCode.unexpectedSize must render as unexpected_size")
        XCTAssertEqual(value.rawValue, Int32(9),
                       "SCErrorCode.unexpectedSize must keep its XDR value")
        XCTAssertEqual(try SCErrorCode.fromXdrJson("\"unexpected_size\""), value,
                       "unexpected_size must read back as SCErrorCode.unexpectedSize")
    }

    func test_SCErrorCode_SCEC_UNEXPECTED_TYPE() throws {
        let value: SCErrorCode = .unexpectedType
        XCTAssertEqual(try value.toXdrJson(), "\"unexpected_type\"",
                       "SCErrorCode.unexpectedType must render as unexpected_type")
        XCTAssertEqual(value.rawValue, Int32(8),
                       "SCErrorCode.unexpectedType must keep its XDR value")
        XCTAssertEqual(try SCErrorCode.fromXdrJson("\"unexpected_type\""), value,
                       "unexpected_type must read back as SCErrorCode.unexpectedType")
    }

    func test_SCErrorCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SCErrorCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SCErrorCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SCErrorCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SCErrorType_SCE_AUTH() throws {
        let value: SCErrorType = .auth
        XCTAssertEqual(try value.toXdrJson(), "\"auth\"",
                       "SCErrorType.auth must render as auth")
        XCTAssertEqual(value.rawValue, Int32(9),
                       "SCErrorType.auth must keep its XDR value")
        XCTAssertEqual(try SCErrorType.fromXdrJson("\"auth\""), value,
                       "auth must read back as SCErrorType.auth")
    }

    func test_SCErrorType_SCE_BUDGET() throws {
        let value: SCErrorType = .budget
        XCTAssertEqual(try value.toXdrJson(), "\"budget\"",
                       "SCErrorType.budget must render as budget")
        XCTAssertEqual(value.rawValue, Int32(7),
                       "SCErrorType.budget must keep its XDR value")
        XCTAssertEqual(try SCErrorType.fromXdrJson("\"budget\""), value,
                       "budget must read back as SCErrorType.budget")
    }

    func test_SCErrorType_SCE_CONTEXT() throws {
        let value: SCErrorType = .context
        XCTAssertEqual(try value.toXdrJson(), "\"context\"",
                       "SCErrorType.context must render as context")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "SCErrorType.context must keep its XDR value")
        XCTAssertEqual(try SCErrorType.fromXdrJson("\"context\""), value,
                       "context must read back as SCErrorType.context")
    }

    func test_SCErrorType_SCE_CONTRACT() throws {
        let value: SCErrorType = .contract
        XCTAssertEqual(try value.toXdrJson(), "\"contract\"",
                       "SCErrorType.contract must render as contract")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SCErrorType.contract must keep its XDR value")
        XCTAssertEqual(try SCErrorType.fromXdrJson("\"contract\""), value,
                       "contract must read back as SCErrorType.contract")
    }

    func test_SCErrorType_SCE_CRYPTO() throws {
        let value: SCErrorType = .crypto
        XCTAssertEqual(try value.toXdrJson(), "\"crypto\"",
                       "SCErrorType.crypto must render as crypto")
        XCTAssertEqual(value.rawValue, Int32(5),
                       "SCErrorType.crypto must keep its XDR value")
        XCTAssertEqual(try SCErrorType.fromXdrJson("\"crypto\""), value,
                       "crypto must read back as SCErrorType.crypto")
    }

    func test_SCErrorType_SCE_EVENTS() throws {
        let value: SCErrorType = .events
        XCTAssertEqual(try value.toXdrJson(), "\"events\"",
                       "SCErrorType.events must render as events")
        XCTAssertEqual(value.rawValue, Int32(6),
                       "SCErrorType.events must keep its XDR value")
        XCTAssertEqual(try SCErrorType.fromXdrJson("\"events\""), value,
                       "events must read back as SCErrorType.events")
    }

    func test_SCErrorType_SCE_OBJECT() throws {
        let value: SCErrorType = .object
        XCTAssertEqual(try value.toXdrJson(), "\"object\"",
                       "SCErrorType.object must render as object")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "SCErrorType.object must keep its XDR value")
        XCTAssertEqual(try SCErrorType.fromXdrJson("\"object\""), value,
                       "object must read back as SCErrorType.object")
    }

    func test_SCErrorType_SCE_STORAGE() throws {
        let value: SCErrorType = .storage
        XCTAssertEqual(try value.toXdrJson(), "\"storage\"",
                       "SCErrorType.storage must render as storage")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "SCErrorType.storage must keep its XDR value")
        XCTAssertEqual(try SCErrorType.fromXdrJson("\"storage\""), value,
                       "storage must read back as SCErrorType.storage")
    }

    func test_SCErrorType_SCE_VALUE() throws {
        let value: SCErrorType = .value
        XCTAssertEqual(try value.toXdrJson(), "\"value\"",
                       "SCErrorType.value must render as value")
        XCTAssertEqual(value.rawValue, Int32(8),
                       "SCErrorType.value must keep its XDR value")
        XCTAssertEqual(try SCErrorType.fromXdrJson("\"value\""), value,
                       "value must read back as SCErrorType.value")
    }

    func test_SCErrorType_SCE_WASM_VM() throws {
        let value: SCErrorType = .wasmVm
        XCTAssertEqual(try value.toXdrJson(), "\"wasm_vm\"",
                       "SCErrorType.wasmVm must render as wasm_vm")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "SCErrorType.wasmVm must keep its XDR value")
        XCTAssertEqual(try SCErrorType.fromXdrJson("\"wasm_vm\""), value,
                       "wasm_vm must read back as SCErrorType.wasmVm")
    }

    func test_SCErrorType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SCErrorType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SCErrorType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SCErrorType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SCErrorXDR_auth_rejectsBareString() throws {
        XCTAssertThrowsError(try SCErrorXDR.fromXdrJson("\"auth\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCErrorXDR.auth: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCErrorXDR")
            XCTAssertEqual(key, "auth",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCErrorXDR_auth_roundTrip() throws {
        let original: SCErrorXDR = .auth(.arithDomain)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCErrorXDR.fromXdrJson(json)
        let viaValue = try SCErrorXDR.fromXdrJsonValue(tree)
        let viaTree = try SCErrorXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCErrorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCErrorXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCErrorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCErrorXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCErrorXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCErrorXDR_budget_rejectsBareString() throws {
        XCTAssertThrowsError(try SCErrorXDR.fromXdrJson("\"budget\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCErrorXDR.budget: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCErrorXDR")
            XCTAssertEqual(key, "budget",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCErrorXDR_budget_roundTrip() throws {
        let original: SCErrorXDR = .budget(.arithDomain)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCErrorXDR.fromXdrJson(json)
        let viaValue = try SCErrorXDR.fromXdrJsonValue(tree)
        let viaTree = try SCErrorXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCErrorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCErrorXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCErrorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCErrorXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCErrorXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCErrorXDR_context_rejectsBareString() throws {
        XCTAssertThrowsError(try SCErrorXDR.fromXdrJson("\"context\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCErrorXDR.context: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCErrorXDR")
            XCTAssertEqual(key, "context",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCErrorXDR_context_roundTrip() throws {
        let original: SCErrorXDR = .context(.arithDomain)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCErrorXDR.fromXdrJson(json)
        let viaValue = try SCErrorXDR.fromXdrJsonValue(tree)
        let viaTree = try SCErrorXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCErrorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCErrorXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCErrorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCErrorXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCErrorXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCErrorXDR_contract_rejectsBareString() throws {
        XCTAssertThrowsError(try SCErrorXDR.fromXdrJson("\"contract\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCErrorXDR.contract: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCErrorXDR")
            XCTAssertEqual(key, "contract",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCErrorXDR_contract_roundTrip() throws {
        let original: SCErrorXDR = .contract(UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCErrorXDR.fromXdrJson(json)
        let viaValue = try SCErrorXDR.fromXdrJsonValue(tree)
        let viaTree = try SCErrorXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCErrorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCErrorXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCErrorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCErrorXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCErrorXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCErrorXDR_crypto_rejectsBareString() throws {
        XCTAssertThrowsError(try SCErrorXDR.fromXdrJson("\"crypto\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCErrorXDR.crypto: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCErrorXDR")
            XCTAssertEqual(key, "crypto",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCErrorXDR_crypto_roundTrip() throws {
        let original: SCErrorXDR = .crypto(.arithDomain)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCErrorXDR.fromXdrJson(json)
        let viaValue = try SCErrorXDR.fromXdrJsonValue(tree)
        let viaTree = try SCErrorXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCErrorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCErrorXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCErrorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCErrorXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCErrorXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCErrorXDR_events_rejectsBareString() throws {
        XCTAssertThrowsError(try SCErrorXDR.fromXdrJson("\"events\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCErrorXDR.events: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCErrorXDR")
            XCTAssertEqual(key, "events",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCErrorXDR_events_roundTrip() throws {
        let original: SCErrorXDR = .events(.arithDomain)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCErrorXDR.fromXdrJson(json)
        let viaValue = try SCErrorXDR.fromXdrJsonValue(tree)
        let viaTree = try SCErrorXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCErrorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCErrorXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCErrorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCErrorXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCErrorXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCErrorXDR_object_rejectsBareString() throws {
        XCTAssertThrowsError(try SCErrorXDR.fromXdrJson("\"object\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCErrorXDR.object: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCErrorXDR")
            XCTAssertEqual(key, "object",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCErrorXDR_object_roundTrip() throws {
        let original: SCErrorXDR = .object(.arithDomain)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCErrorXDR.fromXdrJson(json)
        let viaValue = try SCErrorXDR.fromXdrJsonValue(tree)
        let viaTree = try SCErrorXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCErrorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCErrorXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCErrorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCErrorXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCErrorXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCErrorXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SCErrorXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SCErrorXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SCErrorXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SCErrorXDR_storage_rejectsBareString() throws {
        XCTAssertThrowsError(try SCErrorXDR.fromXdrJson("\"storage\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCErrorXDR.storage: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCErrorXDR")
            XCTAssertEqual(key, "storage",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCErrorXDR_storage_roundTrip() throws {
        let original: SCErrorXDR = .storage(.arithDomain)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCErrorXDR.fromXdrJson(json)
        let viaValue = try SCErrorXDR.fromXdrJsonValue(tree)
        let viaTree = try SCErrorXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCErrorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCErrorXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCErrorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCErrorXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCErrorXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCErrorXDR_value_rejectsBareString() throws {
        XCTAssertThrowsError(try SCErrorXDR.fromXdrJson("\"value\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCErrorXDR.value: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCErrorXDR")
            XCTAssertEqual(key, "value",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCErrorXDR_value_roundTrip() throws {
        let original: SCErrorXDR = .value(.arithDomain)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCErrorXDR.fromXdrJson(json)
        let viaValue = try SCErrorXDR.fromXdrJsonValue(tree)
        let viaTree = try SCErrorXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCErrorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCErrorXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCErrorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCErrorXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCErrorXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCErrorXDR_wasmVm_rejectsBareString() throws {
        XCTAssertThrowsError(try SCErrorXDR.fromXdrJson("\"wasm_vm\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCErrorXDR.wasm_vm: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCErrorXDR")
            XCTAssertEqual(key, "wasm_vm",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCErrorXDR_wasmVm_roundTrip() throws {
        let original: SCErrorXDR = .wasmVm(.arithDomain)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCErrorXDR.fromXdrJson(json)
        let viaValue = try SCErrorXDR.fromXdrJsonValue(tree)
        let viaTree = try SCErrorXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCErrorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCErrorXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCErrorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCErrorXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCErrorXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCMapEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCMapEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCMapEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCMapEntryXDR_roundTrip() throws {
        let original: SCMapEntryXDR = SCMapEntryXDR(key: .void, val: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCMapEntryXDR.fromXdrJson(json)
        let viaValue = try SCMapEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try SCMapEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCMapEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCMapEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCMapEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCMapEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCMapEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCMapXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCMapXDR.fromXdrJson("\"not_an_array\"")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCMapXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCMapXDR_roundTrip() throws {
        let original: SCMapXDR = SCMapXDR(wrapped: [SCMapEntryXDR(key: .void, val: .void)])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCMapXDR.fromXdrJson(json)
        let viaValue = try SCMapXDR.fromXdrJsonValue(tree)
        let viaTree = try SCMapXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCMapXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCMapXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCMapXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCMapXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCMapXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCNonceKeyXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCNonceKeyXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCNonceKeyXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCNonceKeyXDR_roundTrip() throws {
        let original: SCNonceKeyXDR = SCNonceKeyXDR(nonce: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCNonceKeyXDR.fromXdrJson(json)
        let viaValue = try SCNonceKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try SCNonceKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCNonceKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCNonceKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCNonceKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCNonceKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCNonceKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCStringXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCStringXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCStringXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCStringXDR_roundTrip() throws {
        let original: SCStringXDR = "test_string"
        let tree = try SCStringXDRJsonCodec.toXdrJsonValue(original)
        let json = try SCStringXDRJsonCodec.toXdrJson(original)
        let decoded = try SCStringXDRJsonCodec.fromXdrJson(json)
        let viaValue = try SCStringXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try SCStringXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try SCStringXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "SCStringXDR must produce the same tree after a round trip")
        XCTAssertEqual(try SCStringXDRJsonCodec.toXdrJson(decoded), json,
                       "SCStringXDR must produce the same text after a round trip")
        XCTAssertEqual(try SCStringXDRJsonCodec.toXdrJson(viaValue), json,
                       "SCStringXDR must read a tree the same way it reads text")
        XCTAssertEqual(try SCStringXDRJsonCodec.toXdrJson(viaTree), json,
                       "SCStringXDR must read a depth-checked tree the same way")
    }

    func test_SCSymbolXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSymbolXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSymbolXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSymbolXDR_roundTrip() throws {
        let original: SCSymbolXDR = "test_string"
        let tree = try SCSymbolXDRJsonCodec.toXdrJsonValue(original)
        let json = try SCSymbolXDRJsonCodec.toXdrJson(original)
        let decoded = try SCSymbolXDRJsonCodec.fromXdrJson(json)
        let viaValue = try SCSymbolXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try SCSymbolXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try SCSymbolXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "SCSymbolXDR must produce the same tree after a round trip")
        XCTAssertEqual(try SCSymbolXDRJsonCodec.toXdrJson(decoded), json,
                       "SCSymbolXDR must produce the same text after a round trip")
        XCTAssertEqual(try SCSymbolXDRJsonCodec.toXdrJson(viaValue), json,
                       "SCSymbolXDR must read a tree the same way it reads text")
        XCTAssertEqual(try SCSymbolXDRJsonCodec.toXdrJson(viaTree), json,
                       "SCSymbolXDR must read a depth-checked tree the same way")
    }

    func test_SCValType_SCV_ADDRESS() throws {
        let value: SCValType = .address
        XCTAssertEqual(try value.toXdrJson(), "\"address\"",
                       "SCValType.address must render as address")
        XCTAssertEqual(value.rawValue, Int32(18),
                       "SCValType.address must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"address\""), value,
                       "address must read back as SCValType.address")
    }

    func test_SCValType_SCV_BOOL() throws {
        let value: SCValType = .bool
        XCTAssertEqual(try value.toXdrJson(), "\"bool\"",
                       "SCValType.bool must render as bool")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SCValType.bool must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"bool\""), value,
                       "bool must read back as SCValType.bool")
    }

    func test_SCValType_SCV_BYTES() throws {
        let value: SCValType = .bytes
        XCTAssertEqual(try value.toXdrJson(), "\"bytes\"",
                       "SCValType.bytes must render as bytes")
        XCTAssertEqual(value.rawValue, Int32(13),
                       "SCValType.bytes must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"bytes\""), value,
                       "bytes must read back as SCValType.bytes")
    }

    func test_SCValType_SCV_CONTRACT_INSTANCE() throws {
        let value: SCValType = .contractInstance
        XCTAssertEqual(try value.toXdrJson(), "\"contract_instance\"",
                       "SCValType.contractInstance must render as contract_instance")
        XCTAssertEqual(value.rawValue, Int32(19),
                       "SCValType.contractInstance must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"contract_instance\""), value,
                       "contract_instance must read back as SCValType.contractInstance")
    }

    func test_SCValType_SCV_DURATION() throws {
        let value: SCValType = .duration
        XCTAssertEqual(try value.toXdrJson(), "\"duration\"",
                       "SCValType.duration must render as duration")
        XCTAssertEqual(value.rawValue, Int32(8),
                       "SCValType.duration must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"duration\""), value,
                       "duration must read back as SCValType.duration")
    }

    func test_SCValType_SCV_ERROR() throws {
        let value: SCValType = .error
        XCTAssertEqual(try value.toXdrJson(), "\"error\"",
                       "SCValType.error must render as error")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "SCValType.error must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"error\""), value,
                       "error must read back as SCValType.error")
    }

    func test_SCValType_SCV_EXECUTABLE_TAG() throws {
        let value: SCValType = .executableTag
        XCTAssertEqual(try value.toXdrJson(), "\"executable_tag\"",
                       "SCValType.executableTag must render as executable_tag")
        XCTAssertEqual(value.rawValue, Int32(22),
                       "SCValType.executableTag must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"executable_tag\""), value,
                       "executable_tag must read back as SCValType.executableTag")
    }

    func test_SCValType_SCV_I128() throws {
        let value: SCValType = .i128
        XCTAssertEqual(try value.toXdrJson(), "\"i128\"",
                       "SCValType.i128 must render as i128")
        XCTAssertEqual(value.rawValue, Int32(10),
                       "SCValType.i128 must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"i128\""), value,
                       "i128 must read back as SCValType.i128")
    }

    func test_SCValType_SCV_I256() throws {
        let value: SCValType = .i256
        XCTAssertEqual(try value.toXdrJson(), "\"i256\"",
                       "SCValType.i256 must render as i256")
        XCTAssertEqual(value.rawValue, Int32(12),
                       "SCValType.i256 must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"i256\""), value,
                       "i256 must read back as SCValType.i256")
    }

    func test_SCValType_SCV_I32() throws {
        let value: SCValType = .i32
        XCTAssertEqual(try value.toXdrJson(), "\"i32\"",
                       "SCValType.i32 must render as i32")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "SCValType.i32 must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"i32\""), value,
                       "i32 must read back as SCValType.i32")
    }

    func test_SCValType_SCV_I64() throws {
        let value: SCValType = .i64
        XCTAssertEqual(try value.toXdrJson(), "\"i64\"",
                       "SCValType.i64 must render as i64")
        XCTAssertEqual(value.rawValue, Int32(6),
                       "SCValType.i64 must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"i64\""), value,
                       "i64 must read back as SCValType.i64")
    }

    func test_SCValType_SCV_LEDGER_KEY_CONTRACT_INSTANCE() throws {
        let value: SCValType = .ledgerKeyContractInstance
        XCTAssertEqual(try value.toXdrJson(), "\"ledger_key_contract_instance\"",
                       "SCValType.ledgerKeyContractInstance must render as ledger_key_contract_instance")
        XCTAssertEqual(value.rawValue, Int32(20),
                       "SCValType.ledgerKeyContractInstance must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"ledger_key_contract_instance\""), value,
                       "ledger_key_contract_instance must read back as SCValType.ledgerKeyContractInstance")
    }

    func test_SCValType_SCV_LEDGER_KEY_NONCE() throws {
        let value: SCValType = .ledgerKeyNonce
        XCTAssertEqual(try value.toXdrJson(), "\"ledger_key_nonce\"",
                       "SCValType.ledgerKeyNonce must render as ledger_key_nonce")
        XCTAssertEqual(value.rawValue, Int32(21),
                       "SCValType.ledgerKeyNonce must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"ledger_key_nonce\""), value,
                       "ledger_key_nonce must read back as SCValType.ledgerKeyNonce")
    }

    func test_SCValType_SCV_MAP() throws {
        let value: SCValType = .map
        XCTAssertEqual(try value.toXdrJson(), "\"map\"",
                       "SCValType.map must render as map")
        XCTAssertEqual(value.rawValue, Int32(17),
                       "SCValType.map must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"map\""), value,
                       "map must read back as SCValType.map")
    }

    func test_SCValType_SCV_STRING() throws {
        let value: SCValType = .string
        XCTAssertEqual(try value.toXdrJson(), "\"string\"",
                       "SCValType.string must render as string")
        XCTAssertEqual(value.rawValue, Int32(14),
                       "SCValType.string must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"string\""), value,
                       "string must read back as SCValType.string")
    }

    func test_SCValType_SCV_SYMBOL() throws {
        let value: SCValType = .symbol
        XCTAssertEqual(try value.toXdrJson(), "\"symbol\"",
                       "SCValType.symbol must render as symbol")
        XCTAssertEqual(value.rawValue, Int32(15),
                       "SCValType.symbol must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"symbol\""), value,
                       "symbol must read back as SCValType.symbol")
    }

    func test_SCValType_SCV_TIMEPOINT() throws {
        let value: SCValType = .timepoint
        XCTAssertEqual(try value.toXdrJson(), "\"timepoint\"",
                       "SCValType.timepoint must render as timepoint")
        XCTAssertEqual(value.rawValue, Int32(7),
                       "SCValType.timepoint must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"timepoint\""), value,
                       "timepoint must read back as SCValType.timepoint")
    }

    func test_SCValType_SCV_U128() throws {
        let value: SCValType = .u128
        XCTAssertEqual(try value.toXdrJson(), "\"u128\"",
                       "SCValType.u128 must render as u128")
        XCTAssertEqual(value.rawValue, Int32(9),
                       "SCValType.u128 must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"u128\""), value,
                       "u128 must read back as SCValType.u128")
    }

    func test_SCValType_SCV_U256() throws {
        let value: SCValType = .u256
        XCTAssertEqual(try value.toXdrJson(), "\"u256\"",
                       "SCValType.u256 must render as u256")
        XCTAssertEqual(value.rawValue, Int32(11),
                       "SCValType.u256 must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"u256\""), value,
                       "u256 must read back as SCValType.u256")
    }

    func test_SCValType_SCV_U32() throws {
        let value: SCValType = .u32
        XCTAssertEqual(try value.toXdrJson(), "\"u32\"",
                       "SCValType.u32 must render as u32")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "SCValType.u32 must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"u32\""), value,
                       "u32 must read back as SCValType.u32")
    }

    func test_SCValType_SCV_U64() throws {
        let value: SCValType = .u64
        XCTAssertEqual(try value.toXdrJson(), "\"u64\"",
                       "SCValType.u64 must render as u64")
        XCTAssertEqual(value.rawValue, Int32(5),
                       "SCValType.u64 must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"u64\""), value,
                       "u64 must read back as SCValType.u64")
    }

    func test_SCValType_SCV_VEC() throws {
        let value: SCValType = .vec
        XCTAssertEqual(try value.toXdrJson(), "\"vec\"",
                       "SCValType.vec must render as vec")
        XCTAssertEqual(value.rawValue, Int32(16),
                       "SCValType.vec must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"vec\""), value,
                       "vec must read back as SCValType.vec")
    }

    func test_SCValType_SCV_VOID() throws {
        let value: SCValType = .void
        XCTAssertEqual(try value.toXdrJson(), "\"void\"",
                       "SCValType.void must render as void")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "SCValType.void must keep its XDR value")
        XCTAssertEqual(try SCValType.fromXdrJson("\"void\""), value,
                       "void must read back as SCValType.void")
    }

    func test_SCValType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SCValType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SCValType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SCValXDR_address_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"address\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.address: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "address",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_address_roundTrip() throws {
        let original: SCValXDR = .address(.account(try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_bool_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"bool\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.bool: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "bool",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_bool_roundTrip() throws {
        let original: SCValXDR = .bool(true)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_bytes_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"bytes\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.bytes: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "bytes",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_bytes_roundTrip() throws {
        let original: SCValXDR = .bytes(Data([0x01, 0x02, 0x03]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_contractInstance_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"contract_instance\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.contract_instance: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "contract_instance",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_contractInstance_roundTrip() throws {
        let original: SCValXDR = .contractInstance(SCContractInstanceXDR(executable: .token, storage: [SCMapEntryXDR(key: .void, val: .void)]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_duration_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"duration\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.duration: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "duration",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_duration_roundTrip() throws {
        let original: SCValXDR = .duration(UInt64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_error_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"error\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.error: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "error",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_error_roundTrip() throws {
        let original: SCValXDR = .error(.contract(UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_executableTag_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"executable_tag\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.executable_tag: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "executable_tag",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_executableTag_roundTrip() throws {
        let original: SCValXDR = .executableTag("test_string")
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_i128_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"i128\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.i128: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "i128",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_i128_roundTrip() throws {
        let original: SCValXDR = .i128(Int128PartsXDR(hi: Int64(1234567), lo: UInt64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_i256_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"i256\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.i256: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "i256",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_i256_roundTrip() throws {
        let original: SCValXDR = .i256(Int256PartsXDR(hiHi: Int64(1234567), hiLo: UInt64(1234567), loHi: UInt64(1234567), loLo: UInt64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_i32_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"i32\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.i32: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "i32",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_i32_roundTrip() throws {
        let original: SCValXDR = .i32(Int32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_i64_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"i64\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.i64: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "i64",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_i64_roundTrip() throws {
        let original: SCValXDR = .i64(Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_ledgerKeyContractInstance_roundTrip() throws {
        let original: SCValXDR = .ledgerKeyContractInstance
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_ledgerKeyNonce_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"ledger_key_nonce\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.ledger_key_nonce: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "ledger_key_nonce",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_ledgerKeyNonce_roundTrip() throws {
        let original: SCValXDR = .ledgerKeyNonce(SCNonceKeyXDR(nonce: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_map_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"map\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.map: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "map",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_map_roundTrip() throws {
        let original: SCValXDR = .map([SCMapEntryXDR(key: .void, val: .void)])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SCValXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SCValXDR_string_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"string\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.string: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "string",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_string_roundTrip() throws {
        let original: SCValXDR = .string("test_string")
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_symbol_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"symbol\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.symbol: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "symbol",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_symbol_roundTrip() throws {
        let original: SCValXDR = .symbol("test_string")
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_timepoint_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"timepoint\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.timepoint: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "timepoint",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_timepoint_roundTrip() throws {
        let original: SCValXDR = .timepoint(UInt64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_u128_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"u128\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.u128: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "u128",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_u128_roundTrip() throws {
        let original: SCValXDR = .u128(UInt128PartsXDR(hi: UInt64(1234567), lo: UInt64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_u256_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"u256\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.u256: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "u256",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_u256_roundTrip() throws {
        let original: SCValXDR = .u256(UInt256PartsXDR(hiHi: UInt64(1234567), hiLo: UInt64(1234567), loHi: UInt64(1234567), loLo: UInt64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_u32_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"u32\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.u32: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "u32",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_u32_roundTrip() throws {
        let original: SCValXDR = .u32(UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_u64_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"u64\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.u64: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "u64",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_u64_roundTrip() throws {
        let original: SCValXDR = .u64(UInt64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_vec_rejectsBareString() throws {
        XCTAssertThrowsError(try SCValXDR.fromXdrJson("\"vec\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCValXDR.vec: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertEqual(key, "vec",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCValXDR_vec_roundTrip() throws {
        let original: SCValXDR = .vec([.void])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCValXDR_void_roundTrip() throws {
        let original: SCValXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCValXDR.fromXdrJson(json)
        let viaValue = try SCValXDR.fromXdrJsonValue(tree)
        let viaTree = try SCValXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCValXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCValXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCValXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCValXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCValXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCVecXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCVecXDR.fromXdrJson("\"not_an_array\"")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCVecXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCVecXDR_roundTrip() throws {
        let original: SCVecXDR = SCVecXDR(wrapped: [.void])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCVecXDR.fromXdrJson(json)
        let viaValue = try SCVecXDR.fromXdrJsonValue(tree)
        let viaTree = try SCVecXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCVecXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCVecXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCVecXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCVecXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCVecXDR must reach the same bytes through JSON and XDR")
    }

    func test_UInt128PartsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try UInt128PartsXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "UInt128PartsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_UInt128PartsXDR_roundTrip() throws {
        let original: UInt128PartsXDR = UInt128PartsXDR(hi: UInt64(1234567), lo: UInt64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try UInt128PartsXDR.fromXdrJson(json)
        let viaValue = try UInt128PartsXDR.fromXdrJsonValue(tree)
        let viaTree = try UInt128PartsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "UInt128PartsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "UInt128PartsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "UInt128PartsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "UInt128PartsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "UInt128PartsXDR must reach the same bytes through JSON and XDR")
    }

    func test_UInt256PartsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try UInt256PartsXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "UInt256PartsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_UInt256PartsXDR_roundTrip() throws {
        let original: UInt256PartsXDR = UInt256PartsXDR(hiHi: UInt64(1234567), hiLo: UInt64(1234567), loHi: UInt64(1234567), loLo: UInt64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try UInt256PartsXDR.fromXdrJson(json)
        let viaValue = try UInt256PartsXDR.fromXdrJsonValue(tree)
        let viaTree = try UInt256PartsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "UInt256PartsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "UInt256PartsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "UInt256PartsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "UInt256PartsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "UInt256PartsXDR must reach the same bytes through JSON and XDR")
    }
}
