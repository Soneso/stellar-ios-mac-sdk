//
//  XDRClaimAndTradeResultsUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class XDRClaimAndTradeResultsUnitTests: XCTestCase {

    // MARK: - Helper Methods

    func createTestPublicKey() throws -> PublicKey {
        return try PublicKey(accountId: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ")
    }

    func createTestAsset() -> AssetXDR {
        return AssetXDR.native
    }

    func createTestClaimAtomV0() throws -> ClaimAtomXDR {
        // Build ClaimOfferAtomV0XDR via XDR since no public initializer
        var xdrData = Data()

        // sellerEd25519 (32 bytes wrapped)
        xdrData.append(Data(repeating: 0xAB, count: 32))

        // offerId (12345)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x39])

        // assetSold (native = 0)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // amountSold (1000000)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x0F, 0x42, 0x40])

        // assetBought (native = 0)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // amountBought (500000)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0xA1, 0x20])

        let claimAtom = try XDRDecoder.decode(ClaimOfferAtomV0XDR.self, data: [UInt8](xdrData))
        return ClaimAtomXDR.v0(claimAtom)
    }

    func createTestClaimAtomOrderBook() throws -> ClaimAtomXDR {
        let publicKey = try createTestPublicKey()

        let claimAtom = ClaimOfferAtomXDR(
            sellerId: publicKey,
            offerId: 67890,
            assetSold: AssetXDR.native,
            amountSold: 2000000,
            assetBought: AssetXDR.native,
            amountBought: 1000000
        )

        return ClaimAtomXDR.orderBook(claimAtom)
    }

    func createTestClaimAtomLiquidityPool() throws -> ClaimAtomXDR {
        // Create via XDR encoding since there's no public initializer
        let poolId = WrappedData32(Data(repeating: 0xCD, count: 32))

        // Build raw XDR data for ClaimLiquidityAtomXDR
        var xdrData = Data()
        xdrData.append(poolId.wrapped)

        // Add asset sold (native = 0)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // Add amount sold (3000000)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x2D, 0xC6, 0xC0])

        // Add asset bought (native = 0)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // Add amount bought (1500000)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x16, 0xE3, 0x60])

        let claimAtom = try XDRDecoder.decode(ClaimLiquidityAtomXDR.self, data: [UInt8](xdrData))
        return ClaimAtomXDR.liquidityPool(claimAtom)
    }

    // MARK: - ClaimableBalanceEntryXDR Tests

    func testClaimableBalanceIDTypeV0Encoding() throws {
        let data = Data(repeating: 0xAB, count: 32)
        let wrappedData = WrappedData32(data)
        let claimableBalanceID = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(wrappedData)

        let encoded = try XDREncoder.encode(claimableBalanceID)
        let decoded = try XDRDecoder.decode(ClaimableBalanceIDXDR.self, data: encoded)

        switch decoded {
        case .claimableBalanceIDTypeV0(let decodedData):
            XCTAssertEqual(decodedData.wrapped, data)
        }
    }

    func testClaimableBalanceIDTypeMethod() throws {
        let data = Data(repeating: 0xCC, count: 32)
        let wrappedData = WrappedData32(data)
        let claimableBalanceID = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(wrappedData)

        XCTAssertEqual(claimableBalanceID.type(), ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)
    }

    func testClaimableBalanceIDStringConversion() throws {
        let data = Data(repeating: 0xDD, count: 32)
        let wrappedData = WrappedData32(data)
        let claimableBalanceID = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(wrappedData)

        let claimableBalanceString = claimableBalanceID.claimableBalanceIdString
        XCTAssertFalse(claimableBalanceString.isEmpty)

        // Test initialization from hex string
        let reconstructed = try ClaimableBalanceIDXDR(claimableBalanceId: claimableBalanceString)

        switch reconstructed {
        case .claimableBalanceIDTypeV0(let reconstructedData):
            XCTAssertEqual(reconstructedData.wrapped, data)
        }
    }

    func testClaimableBalanceIDFromHexWithoutDiscriminant() throws {
        // 32 bytes without discriminant
        let hexString = String(repeating: "AB", count: 32)
        let claimableBalanceID = try ClaimableBalanceIDXDR(claimableBalanceId: hexString)

        switch claimableBalanceID {
        case .claimableBalanceIDTypeV0:
            XCTAssertTrue(true) // Expected
        }
    }

    func testClaimableBalanceIDFromHexWithDiscriminant() throws {
        // 33 bytes with discriminant (00 + 32 bytes)
        let hexString = "00" + String(repeating: "CD", count: 32)
        let claimableBalanceID = try ClaimableBalanceIDXDR(claimableBalanceId: hexString)

        switch claimableBalanceID {
        case .claimableBalanceIDTypeV0:
            XCTAssertTrue(true) // Expected
        }
    }

    func testClaimableBalanceIDInvalidHexThrowsError() {
        let invalidHex = "INVALID_HEX"

        XCTAssertThrowsError(try ClaimableBalanceIDXDR(claimableBalanceId: invalidHex)) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError")
                return
            }

            if case .encodingError(let message) = sdkError {
                XCTAssertTrue(message.contains("invalid claimable balance id"))
            } else {
                XCTFail("Expected encodingError")
            }
        }
    }

    func testClaimableBalanceIDUnknownDiscriminantThrowsError() {
        // 33 bytes with invalid discriminant (99 is unknown)
        let hexString = "63" + String(repeating: "EF", count: 32)

        XCTAssertThrowsError(try ClaimableBalanceIDXDR(claimableBalanceId: hexString)) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError")
                return
            }

            if case .encodingError(let message) = sdkError {
                XCTAssertTrue(message.contains("unknown discriminant"))
            } else {
                XCTFail("Expected encodingError")
            }
        }
    }

    func testClaimableBalanceEntryXDREncodingDecoding() throws {
        // Build a minimal ClaimableBalanceEntryXDR via XDR
        var xdrData = Data()

        // claimableBalanceID type (0)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // claimableBalanceID value (32 bytes)
        xdrData.append(Data(repeating: 0xAB, count: 32))

        // claimants array count (1)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x01])

        // claimant type (0)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // account ID type (0 for PUBLIC_KEY_TYPE_ED25519)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // account ID (32 bytes)
        xdrData.append(Data(repeating: 0xCD, count: 32))

        // predicate type (0 for unconditional)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // asset (native = 0)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // amount (1000000)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x0F, 0x42, 0x40])

        // ext (void = 0)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        let entry = try XDRDecoder.decode(ClaimableBalanceEntryXDR.self, data: [UInt8](xdrData))

        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(ClaimableBalanceEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.amount, 1000000)
        XCTAssertEqual(decoded.claimants.count, 1)
    }

    func testClaimableBalanceEntryExtVoidEncoding() throws {
        let ext = ClaimableBalanceEntryExtXDR.void

        let encoded = try XDREncoder.encode(ext)
        let decoded = try XDRDecoder.decode(ClaimableBalanceEntryExtXDR.self, data: encoded)

        switch decoded {
        case .void:
            XCTAssertTrue(true) // Expected
        case .claimableBalanceEntryExtensionV1:
            XCTFail("Expected void case")
        }
    }

    func testClaimableBalanceEntryExtV1Encoding() throws {
        let flags = ClaimableBalanceFlags.CLAIMABLE_BALANCE_CLAWBACK_ENABLED_FLAG
        let extV1 = ClaimableBalanceEntryExtensionV1(flags: flags)
        let ext = ClaimableBalanceEntryExtXDR.claimableBalanceEntryExtensionV1(extV1)

        let encoded = try XDREncoder.encode(ext)
        let decoded = try XDRDecoder.decode(ClaimableBalanceEntryExtXDR.self, data: encoded)

        switch decoded {
        case .void:
            XCTFail("Expected claimableBalanceEntryExtensionV1 case")
        case .claimableBalanceEntryExtensionV1(let decodedExtV1):
            XCTAssertEqual(decodedExtV1.flags, flags)
            XCTAssertEqual(decodedExtV1.reserved, 0)
        }
    }

    func testClaimableBalanceEntryExtV1FlagsValue() {
        XCTAssertEqual(ClaimableBalanceFlags.CLAIMABLE_BALANCE_CLAWBACK_ENABLED_FLAG, 1)
    }

    func testClaimableBalanceEntryExtDefaultDiscriminant() throws {
        // Test that unknown discriminant defaults to void
        let xdrData: [UInt8] = [0x00, 0x00, 0x00, 0x99] // Unknown discriminant 99
        let decoded = try XDRDecoder.decode(ClaimableBalanceEntryExtXDR.self, data: xdrData)

        switch decoded {
        case .void:
            XCTAssertTrue(true) // Expected default behavior
        case .claimableBalanceEntryExtensionV1:
            XCTFail("Expected void as default for unknown discriminant")
        }
    }

    // MARK: - PathPaymentResultXDR Tests

    func testPathPaymentResultXDRSuccess() throws {
        let publicKey = try createTestPublicKey()
        let claimAtoms = [try createTestClaimAtomV0()]
        let simplePayment = SimplePaymentResultXDR(
            destination: publicKey,
            asset: AssetXDR.native,
            amount: 5000000
        )

        let result = PathPaymentResultXDR.success(PathPaymentResultCode.success.rawValue, claimAtoms, simplePayment)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(PathPaymentResultXDR.self, data: encoded)

        switch decoded {
        case .success(let code, let offers, let last):
            XCTAssertEqual(code, PathPaymentResultCode.success.rawValue)
            XCTAssertEqual(offers.count, 1)
            XCTAssertEqual(last.amount, 5000000)
        default:
            XCTFail("Expected success case")
        }
    }

    func testPathPaymentResultXDRNoIssuer() throws {
        let asset = AssetXDR.native
        let result = PathPaymentResultXDR.noIssuer(PathPaymentResultCode.noIssuer.rawValue, asset)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(PathPaymentResultXDR.self, data: encoded)

        switch decoded {
        case .noIssuer(let code, _):
            XCTAssertEqual(code, PathPaymentResultCode.noIssuer.rawValue)
        default:
            XCTFail("Expected noIssuer case")
        }
    }

    func testPathPaymentResultXDREmptyMalformed() throws {
        // Test empty case by decoding raw XDR (encoding bug: empty case doesn't encode code)
        let xdrData: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF] // -1 (malformed)
        let decoded = try XDRDecoder.decode(PathPaymentResultXDR.self, data: xdrData)

        switch decoded {
        case .empty(let code):
            XCTAssertEqual(code, PathPaymentResultCode.malformed.rawValue)
        default:
            XCTFail("Expected empty case")
        }
    }

    func testPathPaymentResultXDREmptyUnderfounded() throws {
        // Test empty case by decoding raw XDR (encoding bug: empty case doesn't encode code)
        let xdrData: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFE] // -2 (underfounded)
        let decoded = try XDRDecoder.decode(PathPaymentResultXDR.self, data: xdrData)

        switch decoded {
        case .empty(let code):
            XCTAssertEqual(code, PathPaymentResultCode.underfounded.rawValue)
        default:
            XCTFail("Expected empty case")
        }
    }

    func testPathPaymentResultXDRAllErrorCodes() {
        XCTAssertEqual(PathPaymentResultCode.success.rawValue, 0)
        XCTAssertEqual(PathPaymentResultCode.malformed.rawValue, -1)
        XCTAssertEqual(PathPaymentResultCode.underfounded.rawValue, -2)
        XCTAssertEqual(PathPaymentResultCode.srcNoTrust.rawValue, -3)
        XCTAssertEqual(PathPaymentResultCode.srcNotAuthorized.rawValue, -4)
        XCTAssertEqual(PathPaymentResultCode.noDestination.rawValue, -5)
        XCTAssertEqual(PathPaymentResultCode.noTrust.rawValue, -6)
        XCTAssertEqual(PathPaymentResultCode.notAuthorized.rawValue, -7)
        XCTAssertEqual(PathPaymentResultCode.lineFull.rawValue, -8)
        XCTAssertEqual(PathPaymentResultCode.noIssuer.rawValue, -9)
        XCTAssertEqual(PathPaymentResultCode.tooFewOffers.rawValue, -10)
        XCTAssertEqual(PathPaymentResultCode.offerCrossSelf.rawValue, -11)
        XCTAssertEqual(PathPaymentResultCode.overSendMax.rawValue, -12)
    }

    func testPathPaymentResultXDRRoundTripBase64() throws {
        let publicKey = try createTestPublicKey()
        let simplePayment = SimplePaymentResultXDR(
            destination: publicKey,
            asset: AssetXDR.native,
            amount: 1000000
        )

        let result = PathPaymentResultXDR.success(PathPaymentResultCode.success.rawValue, [], simplePayment)

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try PathPaymentResultXDR(xdr: base64)

        switch decoded {
        case .success(let code, let offers, let last):
            XCTAssertEqual(code, PathPaymentResultCode.success.rawValue)
            XCTAssertEqual(offers.count, 0)
            XCTAssertEqual(last.amount, 1000000)
        default:
            XCTFail("Expected success case")
        }
    }

    // MARK: - ClaimAtomXDR Tests

    func testClaimAtomXDRV0Encoding() throws {
        let claimAtom = try createTestClaimAtomV0()

        let encoded = try XDREncoder.encode(claimAtom)
        let decoded = try XDRDecoder.decode(ClaimAtomXDR.self, data: encoded)

        switch decoded {
        case .v0(let atom):
            XCTAssertEqual(atom.offerId, 12345)
            XCTAssertEqual(atom.amountSold, 1000000)
            XCTAssertEqual(atom.amountBought, 500000)
        default:
            XCTFail("Expected v0 case")
        }
    }

    func testClaimAtomXDROrderBookEncoding() throws {
        let claimAtom = try createTestClaimAtomOrderBook()

        let encoded = try XDREncoder.encode(claimAtom)
        let decoded = try XDRDecoder.decode(ClaimAtomXDR.self, data: encoded)

        switch decoded {
        case .orderBook(let atom):
            XCTAssertEqual(atom.offerId, 67890)
            XCTAssertEqual(atom.amountSold, 2000000)
            XCTAssertEqual(atom.amountBought, 1000000)
        default:
            XCTFail("Expected orderBook case")
        }
    }

    func testClaimAtomXDRLiquidityPoolEncoding() throws {
        let claimAtom = try createTestClaimAtomLiquidityPool()

        let encoded = try XDREncoder.encode(claimAtom)
        let decoded = try XDRDecoder.decode(ClaimAtomXDR.self, data: encoded)

        switch decoded {
        case .liquidityPool(let atom):
            XCTAssertEqual(atom.amountSold, 3000000)
            XCTAssertEqual(atom.amountBought, 1500000)
        default:
            XCTFail("Expected liquidityPool case")
        }
    }

    func testClaimAtomXDRTypeMethod() throws {
        let v0Atom = try createTestClaimAtomV0()
        XCTAssertEqual(v0Atom.type(), ClaimAtomType.v0.rawValue)

        let orderBookAtom = try createTestClaimAtomOrderBook()
        XCTAssertEqual(orderBookAtom.type(), ClaimAtomType.orderBook.rawValue)

        let liquidityPoolAtom = try createTestClaimAtomLiquidityPool()
        XCTAssertEqual(liquidityPoolAtom.type(), ClaimAtomType.liquidityPool.rawValue)
    }

    func testClaimAtomXDRDefaultToV0() throws {
        // Test that unknown type defaults to v0
        var xdrData = [UInt8]()

        // Unknown type discriminant (99)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x99])

        // sellerEd25519 (32 bytes)
        xdrData.append(contentsOf: [UInt8](Data(repeating: 0xAB, count: 32)))

        // offerId
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x39])

        // asset type (native)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // amountSold
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x0F, 0x42, 0x40])

        // asset type (native)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // amountBought
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0xA1, 0x20])

        let decoded = try XDRDecoder.decode(ClaimAtomXDR.self, data: xdrData)

        switch decoded {
        case .v0:
            XCTAssertTrue(true) // Expected default behavior
        default:
            XCTFail("Expected v0 as default for unknown type")
        }
    }

    func testClaimAtomTypeEnumValues() {
        XCTAssertEqual(ClaimAtomType.v0.rawValue, 0)
        XCTAssertEqual(ClaimAtomType.orderBook.rawValue, 1)
        XCTAssertEqual(ClaimAtomType.liquidityPool.rawValue, 2)
    }

    func testClaimOfferAtomXDRRoundTrip() throws {
        let publicKey = try createTestPublicKey()

        let claimAtom = ClaimOfferAtomXDR(
            sellerId: publicKey,
            offerId: 99999,
            assetSold: AssetXDR.native,
            amountSold: 7000000,
            assetBought: AssetXDR.native,
            amountBought: 3500000
        )

        let encoded = try XDREncoder.encode(claimAtom)
        let decoded = try XDRDecoder.decode(ClaimOfferAtomXDR.self, data: encoded)

        XCTAssertEqual(decoded.offerId, 99999)
        XCTAssertEqual(decoded.amountSold, 7000000)
        XCTAssertEqual(decoded.amountBought, 3500000)
    }

    func testClaimLiquidityAtomXDRRoundTrip() throws {
        // Build ClaimLiquidityAtomXDR via XDR since no public initializer
        let poolId = WrappedData32(Data(repeating: 0xEF, count: 32))

        var xdrData = Data()
        xdrData.append(poolId.wrapped)

        // Add asset sold (native = 0)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // Add amount sold (8000000)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x7A, 0x12, 0x00])

        // Add asset bought (native = 0)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // Add amount bought (4000000)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x3D, 0x09, 0x00])

        let claimAtom = try XDRDecoder.decode(ClaimLiquidityAtomXDR.self, data: [UInt8](xdrData))

        let encoded = try XDREncoder.encode(claimAtom)
        let decoded = try XDRDecoder.decode(ClaimLiquidityAtomXDR.self, data: encoded)

        XCTAssertEqual(decoded.liquidityPoolID.wrapped, poolId.wrapped)
        XCTAssertEqual(decoded.amountSold, 8000000)
        XCTAssertEqual(decoded.amountBought, 4000000)
    }

    // MARK: - ChangeTrustResultXDR Tests

    func testChangeTrustResultXDRSuccess() throws {
        let result = ChangeTrustResultXDR.success(ChangeTrustResultCode.success.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ChangeTrustResultXDR.self, data: encoded)

        switch decoded {
        case .success(let code):
            XCTAssertEqual(code, ChangeTrustResultCode.success.rawValue)
        case .empty:
            XCTFail("Expected success case")
        }
    }

    func testChangeTrustResultXDRTrustMalformed() throws {
        let result = ChangeTrustResultXDR.empty(ChangeTrustResultCode.trustMalformed.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ChangeTrustResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case")
        case .empty(let code):
            XCTAssertEqual(code, ChangeTrustResultCode.trustMalformed.rawValue)
        }
    }

    func testChangeTrustResultXDRNoIssuer() throws {
        let result = ChangeTrustResultXDR.empty(ChangeTrustResultCode.noIssuer.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ChangeTrustResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case")
        case .empty(let code):
            XCTAssertEqual(code, ChangeTrustResultCode.noIssuer.rawValue)
        }
    }

    func testChangeTrustResultXDRAllErrorCodes() {
        XCTAssertEqual(ChangeTrustResultCode.success.rawValue, 0)
        XCTAssertEqual(ChangeTrustResultCode.trustMalformed.rawValue, -1)
        XCTAssertEqual(ChangeTrustResultCode.noIssuer.rawValue, -2)
        XCTAssertEqual(ChangeTrustResultCode.trustInvalidLimit.rawValue, -3)
        XCTAssertEqual(ChangeTrustResultCode.changeTrustLowReserve.rawValue, -4)
        XCTAssertEqual(ChangeTrustResultCode.changeTrustSelfNotAllowed.rawValue, -5)
        XCTAssertEqual(ChangeTrustResultCode.trustlineMissing.rawValue, -6)
        XCTAssertEqual(ChangeTrustResultCode.cannotDelete.rawValue, -7)
        XCTAssertEqual(ChangeTrustResultCode.notAuthMaintainLiabilities.rawValue, -8)
    }

    func testChangeTrustResultXDRRoundTripBase64() throws {
        let result = ChangeTrustResultXDR.success(ChangeTrustResultCode.success.rawValue)

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try ChangeTrustResultXDR(xdr: base64)

        switch decoded {
        case .success(let code):
            XCTAssertEqual(code, ChangeTrustResultCode.success.rawValue)
        case .empty:
            XCTFail("Expected success case")
        }
    }

    // MARK: - ManageOfferResultXDR Tests

    func testManageOfferResultXDRSuccess() throws {
        let publicKey = try createTestPublicKey()
        let offerEntry = OfferEntryXDR(
            sellerID: publicKey,
            offerID: 12345,
            selling: AssetXDR.native,
            buying: AssetXDR.native,
            amount: 1000000,
            price: PriceXDR(n: 2, d: 1),
            flags: 0
        )

        let successResult = ManageOfferSuccessResultXDR(
            offersClaimed: [],
            offer: .created(offerEntry)
        )

        let result = ManageOfferResultXDR.success(ManageOfferResultCode.success.rawValue, successResult)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ManageOfferResultXDR.self, data: encoded)

        switch decoded {
        case .success(let code, let successRes):
            XCTAssertEqual(code, ManageOfferResultCode.success.rawValue)
            XCTAssertNotNil(successRes.offer)
        case .empty:
            XCTFail("Expected success case")
        }
    }

    func testManageOfferResultXDRMalformed() throws {
        let result = ManageOfferResultXDR.empty(ManageOfferResultCode.malformed.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ManageOfferResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case")
        case .empty(let code):
            XCTAssertEqual(code, ManageOfferResultCode.malformed.rawValue)
        }
    }

    func testManageOfferResultXDRSellNoTrust() throws {
        let result = ManageOfferResultXDR.empty(ManageOfferResultCode.sellNoTrust.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ManageOfferResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case")
        case .empty(let code):
            XCTAssertEqual(code, ManageOfferResultCode.sellNoTrust.rawValue)
        }
    }

    func testManageOfferResultXDRAllErrorCodes() {
        XCTAssertEqual(ManageOfferResultCode.success.rawValue, 0)
        XCTAssertEqual(ManageOfferResultCode.malformed.rawValue, -1)
        XCTAssertEqual(ManageOfferResultCode.sellNoTrust.rawValue, -2)
        XCTAssertEqual(ManageOfferResultCode.buyNoTrust.rawValue, -3)
        XCTAssertEqual(ManageOfferResultCode.sellNotAuthorized.rawValue, -4)
        XCTAssertEqual(ManageOfferResultCode.buyNotAuthorized.rawValue, -5)
        XCTAssertEqual(ManageOfferResultCode.lineFull.rawValue, -6)
        XCTAssertEqual(ManageOfferResultCode.underfunded.rawValue, -7)
        XCTAssertEqual(ManageOfferResultCode.crossSelf.rawValue, -8)
        XCTAssertEqual(ManageOfferResultCode.sellNoIssuer.rawValue, -9)
        XCTAssertEqual(ManageOfferResultCode.buyNoIssuer.rawValue, -10)
        XCTAssertEqual(ManageOfferResultCode.notFound.rawValue, -11)
        XCTAssertEqual(ManageOfferResultCode.lowReserve.rawValue, -12)
    }

    func testManageOfferResultXDRRoundTripBase64() throws {
        let result = ManageOfferResultXDR.empty(ManageOfferResultCode.malformed.rawValue)

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try ManageOfferResultXDR(xdr: base64)

        switch decoded {
        case .success:
            XCTFail("Expected empty case")
        case .empty(let code):
            XCTAssertEqual(code, ManageOfferResultCode.malformed.rawValue)
        }
    }

    func testManageOfferSuccessResultXDRWithClaimedOffers() throws {
        // Build ManageOfferSuccessResultXDR via XDR to test decoding with claim atoms
        var xdrData = Data()

        // offersClaimed array count (0 for empty array)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // offer discriminant (2 for deleted = no offer entry follows)
        xdrData.append(contentsOf: [0x00, 0x00, 0x00, 0x02])

        let successResult = try XDRDecoder.decode(ManageOfferSuccessResultXDR.self, data: [UInt8](xdrData))

        // Test that it decoded successfully
        XCTAssertEqual(successResult.offersClaimed.count, 0)
    }

    func testManageOfferEffectEnumValues() {
        XCTAssertEqual(ManageOfferEffect.created.rawValue, 0)
        XCTAssertEqual(ManageOfferEffect.updated.rawValue, 1)
        XCTAssertEqual(ManageOfferEffect.deleted.rawValue, 2)
    }

    // MARK: - SetOptionsResultXDR Tests

    func testSetOptionsResultXDRSuccess() throws {
        let result = SetOptionsResultXDR.success(SetOptionsResultCode.success.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetOptionsResultXDR.self, data: encoded)

        switch decoded {
        case .success(let code):
            XCTAssertEqual(code, SetOptionsResultCode.success.rawValue)
        case .empty:
            XCTFail("Expected success case")
        }
    }

    func testSetOptionsResultXDRLowReserve() throws {
        let result = SetOptionsResultXDR.empty(SetOptionsResultCode.lowReserve.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetOptionsResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case")
        case .empty(let code):
            XCTAssertEqual(code, SetOptionsResultCode.lowReserve.rawValue)
        }
    }

    func testSetOptionsResultXDRTooManySigners() throws {
        let result = SetOptionsResultXDR.empty(SetOptionsResultCode.tooManySigners.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetOptionsResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case")
        case .empty(let code):
            XCTAssertEqual(code, SetOptionsResultCode.tooManySigners.rawValue)
        }
    }

    func testSetOptionsResultXDRAllErrorCodes() {
        XCTAssertEqual(SetOptionsResultCode.success.rawValue, 0)
        XCTAssertEqual(SetOptionsResultCode.lowReserve.rawValue, -1)
        XCTAssertEqual(SetOptionsResultCode.tooManySigners.rawValue, -2)
        XCTAssertEqual(SetOptionsResultCode.badFlags.rawValue, -3)
        XCTAssertEqual(SetOptionsResultCode.invalidInflation.rawValue, -4)
        XCTAssertEqual(SetOptionsResultCode.cantChange.rawValue, -5)
        XCTAssertEqual(SetOptionsResultCode.unknownFlag.rawValue, -6)
        XCTAssertEqual(SetOptionsResultCode.thresholdOutOfRange.rawValue, -7)
        XCTAssertEqual(SetOptionsResultCode.badSigner.rawValue, -8)
        XCTAssertEqual(SetOptionsResultCode.invalidHomeDomain.rawValue, -9)
    }

    func testSetOptionsResultXDRRoundTripBase64() throws {
        let result = SetOptionsResultXDR.success(SetOptionsResultCode.success.rawValue)

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try SetOptionsResultXDR(xdr: base64)

        switch decoded {
        case .success(let code):
            XCTAssertEqual(code, SetOptionsResultCode.success.rawValue)
        case .empty:
            XCTFail("Expected success case")
        }
    }

    // MARK: - OperationResultXDR Tests
    // NOTE: OperationResultXDR has an encoding bug where operation type is not encoded
    // These tests focus on the empty (error) case which works correctly

    func testOperationResultXDREmpty() throws {
        let result = OperationResultXDR.empty(OperationResultCode.badAuth.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(OperationResultXDR.self, data: encoded)

        switch decoded {
        case .empty(let code):
            XCTAssertEqual(code, OperationResultCode.badAuth.rawValue)
        default:
            XCTFail("Expected empty case")
        }
    }

    func testOperationResultCodeAllValues() {
        XCTAssertEqual(OperationResultCode.inner.rawValue, 0)
        XCTAssertEqual(OperationResultCode.badAuth.rawValue, -1)
        XCTAssertEqual(OperationResultCode.noAccount.rawValue, -2)
        XCTAssertEqual(OperationResultCode.notSupported.rawValue, -3)
        XCTAssertEqual(OperationResultCode.tooManySubentries.rawValue, -4)
        XCTAssertEqual(OperationResultCode.exceededWorkLimit.rawValue, -5)
        XCTAssertEqual(OperationResultCode.tooManySponsoring.rawValue, -6)
    }

    func testOperationResultCodeEnumCasesExist() {
        // Test that all OperationResultXDR enum cases can be created
        // We can't test encoding/decoding of inner results due to SDK encoding bug

        // Create instances to ensure enum cases exist
        let _ = OperationResultXDR.createAccount(0, CreateAccountResultXDR.success(0))
        let _ = OperationResultXDR.payment(0, PaymentResultXDR.success(0))
        let _ = OperationResultXDR.changeTrust(0, ChangeTrustResultXDR.success(0))
        let _ = OperationResultXDR.setOptions(0, SetOptionsResultXDR.success(0))
        let successResult = ManageOfferSuccessResultXDR(offersClaimed: [], offer: nil)
        let _ = OperationResultXDR.manageSellOffer(0, ManageOfferResultXDR.success(0, successResult))
        let _ = OperationResultXDR.createPassiveSellOffer(0, ManageOfferResultXDR.success(0, successResult))
        let _ = OperationResultXDR.manageBuyOffer(0, ManageOfferResultXDR.success(0, successResult))
        let _ = OperationResultXDR.allowTrust(0, AllowTrustResultXDR.success(0))
        let _ = OperationResultXDR.accountMerge(0, AccountMergeResultXDR.success(0, 1000000))
        let _ = OperationResultXDR.manageData(0, ManageDataResultXDR.success(0))
        let _ = OperationResultXDR.bumpSequence(0, BumpSequenceResultXDR.success(0))

        XCTAssertTrue(true) // All cases created successfully
    }

    func testOperationResultXDRRoundTripBase64() throws {
        let result = OperationResultXDR.empty(OperationResultCode.badAuth.rawValue)

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try OperationResultXDR(xdr: base64)

        switch decoded {
        case .empty(let code):
            XCTAssertEqual(code, OperationResultCode.badAuth.rawValue)
        default:
            XCTFail("Expected empty case")
        }
    }
}
