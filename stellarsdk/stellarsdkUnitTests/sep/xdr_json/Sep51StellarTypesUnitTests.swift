//
//  Sep51StellarTypesUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// The types SEP-0051 §Stellar-Specific Types gives a form no structural rule produces.
///
/// Every arm of every one of them is pinned here, in both directions. These conversions are
/// the ones that cannot be checked by a round trip against themselves: a strkey emitted with
/// the wrong version byte, hex emitted where a strkey belongs, or an asset code trimmed to
/// the wrong floor all round-trip perfectly while being wrong on the wire. The expected
/// strings are therefore external values, not values this SDK produced.
///
/// The 32 bytes `00 01 02 … 1f` are the shared key material, so the same bytes appear under
/// five different version bytes and the difference between the renderings is visible.
final class Sep51StellarTypesUnitTests: XCTestCase {

    // MARK: - Public keys

    func testPublicKeyRendersAsAnAccountStrkey() throws {
        let key = try PublicKey(Self.keyBytes)
        XCTAssertEqual(try key.toXdrJson(), Self.quoted(Self.accountStrKey))
        XCTAssertEqual(try PublicKey.fromXdrJson(Self.quoted(Self.accountStrKey)).bytes, Self.keyBytes)
    }

    func testAccountIdAndNodeIdCodecsRenderTheSameAccountStrkey() throws {
        let key = try PublicKey(Self.keyBytes)
        XCTAssertEqual(try AccountIDXDRJsonCodec.toXdrJson(key), Self.quoted(Self.accountStrKey))
        XCTAssertEqual(try NodeIDXDRJsonCodec.toXdrJson(key), Self.quoted(Self.accountStrKey))

        XCTAssertEqual(try AccountIDXDRJsonCodec.fromXdrJson(Self.quoted(Self.accountStrKey)).bytes,
                       Self.keyBytes)
        XCTAssertEqual(try NodeIDXDRJsonCodec.fromXdrJson(Self.quoted(Self.accountStrKey)).bytes,
                       Self.keyBytes)
    }

    // MARK: - Muxed accounts

    func testMuxedAccountRendersItsEd25519ArmAsAnAccountStrkey() throws {
        let muxed = MuxedAccountXDR.ed25519(Self.keyBytes)
        XCTAssertEqual(try muxed.toXdrJson(), Self.quoted(Self.accountStrKey))

        let read = try MuxedAccountXDR.fromXdrJson(Self.quoted(Self.accountStrKey))
        XCTAssertEqual(try Self.base64(read), "AAAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4f")
    }

    func testMuxedAccountRendersItsMed25519ArmAsAMuxedStrkey() throws {
        let muxed = MuxedAccountXDR.med25519(
            MuxedAccountMed25519XDR(id: 7, sourceAccountEd25519: Self.keyBytes))
        XCTAssertEqual(try muxed.toXdrJson(), Self.quoted(Self.muxedStrKeyId7))

        let read = try MuxedAccountXDR.fromXdrJson(Self.quoted(Self.muxedStrKeyId7))
        guard case .med25519(let body) = read else {
            return XCTFail("the muxed strkey did not read back as a med25519 account")
        }
        XCTAssertEqual(body.id, 7)
        XCTAssertEqual(body.sourceAccountEd25519, Self.keyBytes)
    }

    /// The muxed strkey packs the ed25519 key first and the identifier second, which is the
    /// reverse of the XDR union body. Decoding the emitted strkey and reading the two halves
    /// back states the order directly rather than leaving it implied by a matching string.
    func testMuxedStrkeyPacksTheKeyBeforeTheBigEndianIdentifier() throws {
        let id: UInt64 = 0x0102030405060708
        let muxed = MuxedAccountMed25519XDR(id: id, sourceAccountEd25519: Self.keyBytes)
        let strKey = try XCTUnwrap(Self.unquoted(try muxed.toXdrJsonValue()))

        let raw = try strKey.decodeMed25519PublicKey()
        XCTAssertEqual(raw.count, 40)
        XCTAssertEqual(Array(raw.prefix(32)), Self.keyBytes)
        XCTAssertEqual(Array(raw.suffix(8)), [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
    }

    func testMuxedStrkeyVariesWithTheIdentifier() throws {
        let zero = MuxedAccountMed25519XDR(id: 0, sourceAccountEd25519: Self.keyBytes)
        let seven = MuxedAccountMed25519XDR(id: 7, sourceAccountEd25519: Self.keyBytes)
        let maximum = MuxedAccountMed25519XDR(id: UInt64.max, sourceAccountEd25519: Self.keyBytes)

        XCTAssertEqual(try zero.toXdrJson(), Self.quoted(Self.muxedStrKeyId0))
        XCTAssertEqual(try seven.toXdrJson(), Self.quoted(Self.muxedStrKeyId7))
        XCTAssertEqual(try maximum.toXdrJson(), Self.quoted(Self.muxedStrKeyIdMax))
    }

    func testMuxedAccountBodyOfTheOperationUnionRendersAsAMuxedStrkey() throws {
        let body = MuxedAccountXDRMed25519XDR(id: 7, ed25519: Uint256XDR(Data(Self.keyBytes)))
        XCTAssertEqual(try body.toXdrJson(), Self.quoted(Self.muxedStrKeyId7))

        let read = try MuxedAccountXDRMed25519XDR.fromXdrJson(Self.quoted(Self.muxedStrKeyId7))
        XCTAssertEqual(read.id, 7)
        XCTAssertEqual(read.ed25519.wrapped, Data(Self.keyBytes))
    }

    // MARK: - Contract addresses

    /// `Hash`, `ContractID` and `PoolID` are the same Swift type and have three different wire
    /// forms, so the same bytes must render three different ways.
    func testHashContractIdAndPoolIdRenderTheSameBytesDifferently() throws {
        let bytes = WrappedData32(Data(Self.keyBytes))

        XCTAssertEqual(try HashXDRJsonCodec.toXdrJson(bytes), Self.quoted(Self.hashHex))
        XCTAssertEqual(try ContractIDXDRJsonCodec.toXdrJson(bytes), Self.quoted(Self.contractStrKey))
        XCTAssertEqual(try PoolIDXDRJsonCodec.toXdrJson(bytes), Self.quoted(Self.poolStrKey))

        XCTAssertEqual(try HashXDRJsonCodec.fromXdrJson(Self.quoted(Self.hashHex)), bytes)
        XCTAssertEqual(try ContractIDXDRJsonCodec.fromXdrJson(Self.quoted(Self.contractStrKey)), bytes)
        XCTAssertEqual(try PoolIDXDRJsonCodec.fromXdrJson(Self.quoted(Self.poolStrKey)), bytes)
    }

    // MARK: - SCAddress

    func testScAddressRendersEveryArmAsItsOwnStrkey() throws {
        let cases: [(SCAddressXDR, String)] = [
            (.account(try PublicKey(Self.keyBytes)), Self.accountStrKey),
            (.contract(WrappedData32(Data(Self.keyBytes))), Self.contractStrKey),
            (.muxedAccount(MuxedAccountMed25519XDR(id: 7, sourceAccountEd25519: Self.keyBytes)),
             Self.muxedStrKeyId7),
            (.claimableBalanceId(.claimableBalanceIDTypeV0(HashXDR(Data(Self.keyBytes)))),
             Self.balanceStrKey),
            (.liquidityPoolId(WrappedData32(Data(Self.keyBytes))), Self.poolStrKey)
        ]

        for (address, strKey) in cases {
            XCTAssertEqual(try address.toXdrJson(), Self.quoted(strKey))
            let read = try SCAddressXDR.fromXdrJson(Self.quoted(strKey))
            XCTAssertEqual(try Self.base64(read), try Self.base64(address))
        }
    }

    /// The contract and liquidity pool arms are the place a hexadecimal accessor would be
    /// reached for by mistake: both hold raw bytes and both have a hex spelling elsewhere in
    /// the SDK. SEP-0051 requires the `C` and `L` strkeys.
    func testScAddressNeverRendersContractOrPoolArmsAsHex() throws {
        let contract = SCAddressXDR.contract(WrappedData32(Data(Self.keyBytes)))
        let pool = SCAddressXDR.liquidityPoolId(WrappedData32(Data(Self.keyBytes)))

        XCTAssertFalse(try contract.toXdrJson().contains(Self.hashHex))
        XCTAssertFalse(try pool.toXdrJson().contains(Self.hashHex))
        XCTAssertTrue(try contract.toXdrJson().hasPrefix("\"C"))
        XCTAssertTrue(try pool.toXdrJson().hasPrefix("\"L"))
    }

    func testScAddressRejectsAStrkeyOfAnUnrelatedType() {
        XCTAssertThrowsError(try SCAddressXDR.fromXdrJson(Self.quoted(Self.preAuthTxStrKey))) { error in
            guard case XdrJsonError.invalidValue(let type, _, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "SCAddressXDR")
        }
    }

    // MARK: - SignerKey

    func testSignerKeyRendersEveryArmAsItsOwnStrkey() throws {
        let payload = Ed25519SignedPayload(ed25519: Uint256XDR(Data(Self.keyBytes)),
                                           payload: Data([0xff]))
        let cases: [(SignerKeyXDR, String)] = [
            (.ed25519(Uint256XDR(Data(Self.keyBytes))), Self.accountStrKey),
            (.preAuthTx(Uint256XDR(Data(Self.keyBytes))), Self.preAuthTxStrKey),
            (.hashX(Uint256XDR(Data(Self.keyBytes))), Self.hashXStrKey),
            (.signedPayload(payload), Self.signedPayloadOneByteStrKey)
        ]

        for (key, strKey) in cases {
            XCTAssertEqual(try key.toXdrJson(), Self.quoted(strKey))
            let read = try SignerKeyXDR.fromXdrJson(Self.quoted(strKey))
            XCTAssertEqual(try Self.base64(read), try Self.base64(key))
        }
    }

    func testSignerKeyRejectsAStrkeyOfAnUnrelatedType() {
        XCTAssertThrowsError(try SignerKeyXDR.fromXdrJson(Self.quoted(Self.contractStrKey))) { error in
            guard case XdrJsonError.invalidValue(let type, _, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "SignerKeyXDR")
        }
    }

    // MARK: - Signed payloads

    /// A signed payload of one to three bytes is inside the accepted domain: the forty-byte
    /// floor of the strkey applies to the XDR-padded region, not to the payload.
    func testShortSignedPayloadsRender() throws {
        let expected = [Self.signedPayloadOneByteStrKey,
                        Self.signedPayloadTwoByteStrKey,
                        Self.signedPayloadThreeByteStrKey]
        let payloads = [Data([0xff]), Data([0xfe, 0xff]), Data([0xfd, 0xfe, 0xff])]

        for (payload, strKey) in zip(payloads, expected) {
            let value = Ed25519SignedPayload(ed25519: Uint256XDR(Data(Self.keyBytes)), payload: payload)
            XCTAssertEqual(try value.toXdrJson(), Self.quoted(strKey))
            XCTAssertEqual(try Ed25519SignedPayload.fromXdrJson(Self.quoted(strKey)).payload, payload)
        }
    }

    func testFullLengthSignedPayloadRenders() throws {
        let payload = Data((0..<64).map { UInt8($0) })
        let value = Ed25519SignedPayload(ed25519: Uint256XDR(Data(Self.keyBytes)), payload: payload)

        XCTAssertEqual(try value.toXdrJson(), Self.quoted(Self.signedPayloadFullStrKey))
        XCTAssertEqual(try Ed25519SignedPayload.fromXdrJson(Self.quoted(Self.signedPayloadFullStrKey)).payload,
                       payload)
    }

    /// A payload of zero length is valid XDR and has no strkey the ecosystem accepts, so it
    /// is reported as unrepresentable rather than emitted.
    func testZeroLengthSignedPayloadIsUnrepresentable() {
        let value = Ed25519SignedPayload(ed25519: Uint256XDR(Data(Self.keyBytes)), payload: Data())

        XCTAssertThrowsError(try value.toXdrJson()) { error in
            guard case XdrJsonError.unrepresentable(let type, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "Ed25519SignedPayload")
        }

        XCTAssertThrowsError(try SignerKeyXDR.signedPayload(value).toXdrJson()) { error in
            guard case XdrJsonError.unrepresentable = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }

    /// The strkey a zero length payload would encode to is shorter than the shortest signed
    /// payload strkey, so it is rejected as not being a signed payload strkey at all.
    func testZeroLengthSignedPayloadStrkeyIsRejectedOnInput() {
        XCTAssertThrowsError(
            try Ed25519SignedPayload.fromXdrJson(Self.quoted(Self.signedPayloadEmptyStrKey))
        ) { error in
            guard case XdrJsonError.invalidValue(let type, let key, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "Ed25519SignedPayload")
            XCTAssertNil(key)
            XCTAssertTrue(message.contains("not a signed payload strkey"), message)
        }
    }

    func testOverLongSignedPayloadIsRejected() {
        let value = Ed25519SignedPayload(ed25519: Uint256XDR(Data(Self.keyBytes)),
                                         payload: Data(count: 65))
        XCTAssertThrowsError(try value.toXdrJson()) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "Ed25519SignedPayload")
            XCTAssertEqual(key, "payload")
        }
    }

    // MARK: - Claimable balance identifiers

    func testClaimableBalanceIdRendersTheThirtyThreeByteForm() throws {
        let value = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(HashXDR(Data(Self.keyBytes)))
        XCTAssertEqual(try value.toXdrJson(), Self.quoted(Self.balanceStrKey))

        let read = try ClaimableBalanceIDXDR.fromXdrJson(Self.quoted(Self.balanceStrKey))
        guard case .claimableBalanceIDTypeV0(let hash) = read else {
            return XCTFail("the balance strkey did not read back as a v0 identifier")
        }
        XCTAssertEqual(hash.wrapped, Data(Self.keyBytes))

        let raw = try Self.balanceStrKey.decodeClaimableBalanceId()
        XCTAssertEqual(raw.count, 33)
        XCTAssertEqual(raw.first, 0x00)
    }

    func testClaimableBalanceIdRejectsAnUnknownLeadingTypeByte() {
        XCTAssertThrowsError(
            try ClaimableBalanceIDXDR.fromXdrJson(Self.quoted(Self.balanceStrKeyUnknownType))
        ) { error in
            guard case XdrJsonError.invalidValue(let type, let key, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "ClaimableBalanceIDXDR")
            XCTAssertNil(key)
            XCTAssertTrue(message.contains("not a valid strkey"), message)
        }
    }

    // MARK: - Strkey integrity

    func testStrkeyWithACorruptedChecksumIsRejected() {
        let corrupted = String(Self.accountStrKey.dropLast()) + "A"
        XCTAssertNotEqual(corrupted, Self.accountStrKey)

        XCTAssertThrowsError(try PublicKey.fromXdrJson(Self.quoted(corrupted))) { error in
            guard case XdrJsonError.invalidValue(let type, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "PublicKey")
            XCTAssertTrue(message.contains("not a valid strkey"), message)
        }

        XCTAssertThrowsError(try ContractIDXDRJsonCodec.fromXdrJson(
            Self.quoted(String(Self.contractStrKey.dropLast()) + "A")))
        XCTAssertThrowsError(try PoolIDXDRJsonCodec.fromXdrJson(
            Self.quoted(String(Self.poolStrKey.dropLast()) + "A")))
    }

    // MARK: - Asset codes

    func testAssetCode4TrimsToNothingWhenEveryByteIsNul() throws {
        let code = AssetCode4XDR(Data(count: 4))
        XCTAssertEqual(try AssetCode4XDRJsonCodec.toXdrJson(code), "\"\"")
        XCTAssertEqual(try AssetCode4XDRJsonCodec.fromXdrJson("\"\"").wrapped, Data(count: 4))
    }

    /// The twelve-character code keeps a floor of five bytes, which is the only thing that
    /// keeps the two `AssetCode` arms distinguishable once the union renders as a bare
    /// string. An all-NUL code therefore renders as five escaped NULs and must not throw.
    func testAssetCode12KeepsItsFiveByteFloorForAnAllNulCode() throws {
        let code = AssetCode12XDR(Data(count: 12))
        XCTAssertEqual(try AssetCode12XDRJsonCodec.toXdrJson(code), #""\\0\\0\\0\\0\\0""#)
        XCTAssertEqual(try AssetCode12XDRJsonCodec.fromXdrJson(#""\\0\\0\\0\\0\\0""#).wrapped,
                       Data(count: 12))
    }

    func testAssetCode12KeepsEveryByteOfAFullWidthCode() throws {
        let code = AssetCode12XDR(Data("ABCDEFGHIABC".utf8))
        XCTAssertEqual(try AssetCode12XDRJsonCodec.toXdrJson(code), "\"ABCDEFGHIABC\"")
        XCTAssertEqual(try AssetCode12XDRJsonCodec.fromXdrJson("\"ABCDEFGHIABC\"").wrapped,
                       Data("ABCDEFGHIABC".utf8))
    }

    // MARK: - The AssetCode union

    func testAssetCodeUnionDispatchesOnDecodedLength() throws {
        let short = try AllowTrustOpAssetXDR.fromXdrJson("\"ABCD\"")
        guard case .alphanum4(let four) = short else {
            return XCTFail("four bytes did not select the four-character arm")
        }
        XCTAssertEqual(four.wrapped, Data("ABCD".utf8))

        let long = try AllowTrustOpAssetXDR.fromXdrJson("\"ABCDE\"")
        guard case .alphanum12(let twelve) = long else {
            return XCTFail("five bytes did not select the twelve-character arm")
        }
        XCTAssertEqual(twelve.wrapped, Data("ABCDE".utf8) + Data(count: 7))
    }

    func testAssetCodeUnionReadsAnAllNulTwelveCharacterCode() throws {
        let value = try AllowTrustOpAssetXDR.fromXdrJson(#""\\0\\0\\0\\0\\0""#)
        guard case .alphanum12(let twelve) = value else {
            return XCTFail("five NUL bytes did not select the twelve-character arm")
        }
        XCTAssertEqual(twelve.wrapped, Data(count: 12))
        XCTAssertEqual(try value.toXdrJson(), #""\\0\\0\\0\\0\\0""#)
    }

    func testAssetCodeUnionReadsAnEmptyStringAsTheFourCharacterArm() throws {
        let value = try AllowTrustOpAssetXDR.fromXdrJson("\"\"")
        guard case .alphanum4(let four) = value else {
            return XCTFail("no bytes did not select the four-character arm")
        }
        XCTAssertEqual(four.wrapped, Data(count: 4))
    }

    func testAssetCodeUnionRejectsMoreThanTwelveBytes() {
        XCTAssertThrowsError(try AllowTrustOpAssetXDR.fromXdrJson("\"ABCDEFGHIJKLM\"")) { error in
            guard case XdrJsonError.invalidValue(let type, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "AllowTrustOpAssetXDR")
            XCTAssertTrue(message.contains("at most 12 bytes"), message)
        }
    }

    // MARK: - Integer parts

    func testHundredAndTwentyEightBitPartsRenderTheirFullRange() throws {
        let signedCases = [("f////////////////////w==", "170141183460469231731687303715884105727"),
                           ("gAAAAAAAAAAAAAAAAAAAAA==", "-170141183460469231731687303715884105728"),
                           ("/////////////////////w==", "-1"),
                           ("AAAAAAAAAAAAAAAAAAAAAA==", "0")]
        for (base64, decimal) in signedCases {
            let value = try XDRDecoder.decode(Int128PartsXDR.self, data: try Self.data(base64))
            XCTAssertEqual(try value.toXdrJson(), Self.quoted(decimal))
            XCTAssertEqual(try Self.base64(try Int128PartsXDR.fromXdrJson(Self.quoted(decimal))), base64)
        }

        let unsignedCases = [("/////////////////////w==", "340282366920938463463374607431768211455"),
                             ("AAAAAAAAAAAAAAAAAAAAAQ==", "1")]
        for (base64, decimal) in unsignedCases {
            let value = try XDRDecoder.decode(UInt128PartsXDR.self, data: try Self.data(base64))
            XCTAssertEqual(try value.toXdrJson(), Self.quoted(decimal))
            XCTAssertEqual(try Self.base64(try UInt128PartsXDR.fromXdrJson(Self.quoted(decimal))), base64)
        }
    }

    func testTwoHundredAndFiftySixBitPartsRenderTheirFullRange() throws {
        let signedCases = [
            ("f/////////////////////////////////////////8=",
             "57896044618658097711785492504343953926634992332820282019728792003956564819967"),
            ("gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
             "-57896044618658097711785492504343953926634992332820282019728792003956564819968"),
            ("//////////////////////////////////////////8=", "-1")
        ]
        for (base64, decimal) in signedCases {
            let value = try XDRDecoder.decode(Int256PartsXDR.self, data: try Self.data(base64))
            XCTAssertEqual(try value.toXdrJson(), Self.quoted(decimal))
            XCTAssertEqual(try Self.base64(try Int256PartsXDR.fromXdrJson(Self.quoted(decimal))), base64)
        }

        let unsignedCases = [
            ("//////////////////////////////////////////8=",
             "115792089237316195423570985008687907853269984665640564039457584007913129639935"),
            ("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE=", "1")
        ]
        for (base64, decimal) in unsignedCases {
            let value = try XDRDecoder.decode(UInt256PartsXDR.self, data: try Self.data(base64))
            XCTAssertEqual(try value.toXdrJson(), Self.quoted(decimal))
            XCTAssertEqual(try Self.base64(try UInt256PartsXDR.fromXdrJson(Self.quoted(decimal))), base64)
        }
    }

    func testIntegerPartsRejectAValueOutsideTheirWidth() {
        XCTAssertThrowsError(
            try Int128PartsXDR.fromXdrJson(Self.quoted("170141183460469231731687303715884105728"))
        ) { error in
            guard case XdrJsonError.invalidValue(let type, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "Int128PartsXDR")
            XCTAssertTrue(message.contains("out of range for int128"), message)
        }

        XCTAssertThrowsError(try UInt128PartsXDR.fromXdrJson(Self.quoted("-1"))) { error in
            guard case XdrJsonError.invalidValue = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }

    // MARK: - Fixtures

    private static let keyBytes: [UInt8] = (0..<32).map { UInt8($0) }

    private static let hashHex = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"
    private static let accountStrKey = "GAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB7JZX"
    private static let preAuthTxStrKey = "TAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6ULG"
    private static let hashXStrKey = "XAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB7QO7"
    private static let contractStrKey = "CAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6N4O"
    private static let poolStrKey = "LAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6UWD"
    private static let balanceStrKey = "BAAAAAICAMCAKBQHBAEQUCYMBUHA6EARCIJRIFIWC4MBSGQ3DQOR4H2TOM"

    /// The claimable balance strkey SEP-23 lists as invalid: canonical base-32 over a body of
    /// the 33 bytes a claimable balance id is wide, carrying the checksum that body produces,
    /// whose leading type discriminant reads 1 where CLAIMABLE_BALANCE_ID_TYPE_V0 is the only
    /// type the XDR union defines.
    private static let balanceStrKeyUnknownType = "BAAT6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGXACA"

    private static let muxedStrKeyId0 =
        "MAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6AAAAAAAAAAAABEJ6"
    private static let muxedStrKeyId7 =
        "MAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6AAAAAAAAAAAA6X66"
    private static let muxedStrKeyIdMax =
        "MAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB77777777777776UTS"

    private static let signedPayloadEmptyStrKey =
        "PAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6AAAAAAESYQ"
    private static let signedPayloadOneByteStrKey =
        "PAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6AAAAAA76AAAAB2NM"
    private static let signedPayloadTwoByteStrKey =
        "PAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6AAAAABP57YAABYYC"
    private static let signedPayloadThreeByteStrKey =
        "PAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6AAAAAB737X7AAZYI"
    private static let signedPayloadFullStrKey =
        "PAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6AAAABAAAAICAMCAKBQHBAEQUCYMBUHA6"
        + "EARCIJRIFIWC4MBSGQ3DQOR4HZAEERCGJBFEYTSQKJKFMWC2LRPGAYTEMZUGU3DOOBZHI5TYPJ6H745A"

    // MARK: - Helpers

    private static func quoted(_ text: String) -> String {
        "\"\(text)\""
    }

    private static func unquoted(_ value: XdrJsonValue) -> String? {
        guard case .string(let text) = value else { return nil }
        return text
    }

    private static func data(_ base64: String) throws -> Data {
        try XCTUnwrap(Data(base64Encoded: base64), "not base64: \(base64)")
    }

    private static func base64(_ value: XDREncodable) throws -> String {
        Data(try XDREncoder.encode(value)).base64EncodedString()
    }
}
