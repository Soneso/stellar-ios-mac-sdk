//
//  TrustLineFlagsOpXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TrustLineFlagsOpXDRUnitTests: XCTestCase {

    // MARK: - Test Data Helpers

    private let testAccountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
    private let testIssuerIdString = "GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"

    // MARK: - SetTrustLineFlagsOpXDR Basic Tests

    func testSetTrustLineFlagsOpXDREncodeDecode() throws {
        let accountPublicKey = try PublicKey(accountId: testAccountIdString)
        let asset = AssetXDR.native

        let op = SetTrustLineFlagsOpXDR(
            accountID: accountPublicKey,
            asset: asset,
            setFlags: TrustLineFlags.AUTHORIZED_FLAG,
            clearFlags: 0
        )

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.accountID.accountId, testAccountIdString)
        XCTAssertEqual(decoded.setFlags, TrustLineFlags.AUTHORIZED_FLAG)
        XCTAssertEqual(decoded.clearFlags, 0)
    }

    func testSetTrustLineFlagsOpXDRClearAuthorized() throws {
        let accountPublicKey = try PublicKey(accountId: testAccountIdString)
        let asset = AssetXDR.native

        let op = SetTrustLineFlagsOpXDR(
            accountID: accountPublicKey,
            asset: asset,
            setFlags: 0,
            clearFlags: TrustLineFlags.AUTHORIZED_FLAG
        )

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.setFlags, 0)
        XCTAssertEqual(decoded.clearFlags, TrustLineFlags.AUTHORIZED_FLAG)
    }

    func testSetTrustLineFlagsOpXDRSetAuthorized() throws {
        let accountPublicKey = try PublicKey(accountId: testAccountIdString)
        let issuerPublicKey = try PublicKey(accountId: testIssuerIdString)

        let assetCodeData = Data("USD".utf8) + Data(repeating: 0, count: 1)
        let assetCodeWrapped = WrappedData4(assetCodeData)
        let asset = AssetXDR.alphanum4(Alpha4XDR(assetCode: assetCodeWrapped, issuer: issuerPublicKey))

        let op = SetTrustLineFlagsOpXDR(
            accountID: accountPublicKey,
            asset: asset,
            setFlags: TrustLineFlags.AUTHORIZED_FLAG,
            clearFlags: 0
        )

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.setFlags, TrustLineFlags.AUTHORIZED_FLAG)
        XCTAssertEqual(decoded.clearFlags, 0)
        XCTAssertEqual(decoded.accountID.accountId, testAccountIdString)
    }

    func testSetTrustLineFlagsOpXDRClearAndSetFlags() throws {
        let accountPublicKey = try PublicKey(accountId: testAccountIdString)
        let asset = AssetXDR.native

        // Clear AUTHORIZED, set AUTHORIZED_TO_MAINTAIN_LIABILITIES
        let op = SetTrustLineFlagsOpXDR(
            accountID: accountPublicKey,
            asset: asset,
            setFlags: TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG,
            clearFlags: TrustLineFlags.AUTHORIZED_FLAG
        )

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.setFlags, TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG)
        XCTAssertEqual(decoded.clearFlags, TrustLineFlags.AUTHORIZED_FLAG)
    }

    func testSetTrustLineFlagsOpXDRWithAlphanum4Asset() throws {
        let accountPublicKey = try PublicKey(accountId: testAccountIdString)
        let issuerPublicKey = try PublicKey(accountId: testIssuerIdString)

        let assetCodeData = Data("USDC".utf8)
        let assetCodeWrapped = WrappedData4(assetCodeData)
        let asset = AssetXDR.alphanum4(Alpha4XDR(assetCode: assetCodeWrapped, issuer: issuerPublicKey))

        let op = SetTrustLineFlagsOpXDR(
            accountID: accountPublicKey,
            asset: asset,
            setFlags: TrustLineFlags.AUTHORIZED_FLAG | TrustLineFlags.TRUSTLINE_CLAWBACK_ENABLED_FLAG,
            clearFlags: 0
        )

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.setFlags, TrustLineFlags.AUTHORIZED_FLAG | TrustLineFlags.TRUSTLINE_CLAWBACK_ENABLED_FLAG)
        XCTAssertEqual(decoded.clearFlags, 0)

        switch decoded.asset {
        case .alphanum4:
            XCTAssertEqual(decoded.asset.assetCode, "USDC")
            XCTAssertEqual(decoded.asset.issuer?.accountId, testIssuerIdString)
        default:
            XCTFail("Expected alphanum4 asset type")
        }
    }

    func testSetTrustLineFlagsOpXDRWithAlphanum12Asset() throws {
        let accountPublicKey = try PublicKey(accountId: testAccountIdString)
        let issuerPublicKey = try PublicKey(accountId: testIssuerIdString)

        let assetCodeString = "LONGASSET123"
        let assetCodeData = Data(assetCodeString.utf8)
        let assetCodeWrapped = WrappedData12(assetCodeData)
        let asset = AssetXDR.alphanum12(Alpha12XDR(assetCode: assetCodeWrapped, issuer: issuerPublicKey))

        let op = SetTrustLineFlagsOpXDR(
            accountID: accountPublicKey,
            asset: asset,
            setFlags: TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG,
            clearFlags: TrustLineFlags.AUTHORIZED_FLAG
        )

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.setFlags, TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG)
        XCTAssertEqual(decoded.clearFlags, TrustLineFlags.AUTHORIZED_FLAG)

        switch decoded.asset {
        case .alphanum12:
            XCTAssertEqual(decoded.asset.assetCode, "LONGASSET123")
            XCTAssertEqual(decoded.asset.issuer?.accountId, testIssuerIdString)
        default:
            XCTFail("Expected alphanum12 asset type")
        }
    }

    func testSetTrustLineFlagsOpXDRRoundTrip() throws {
        let accountPublicKey = try PublicKey(accountId: testAccountIdString)
        let issuerPublicKey = try PublicKey(accountId: testIssuerIdString)

        let assetCodeData = Data("EUR".utf8) + Data(repeating: 0, count: 1)
        let assetCodeWrapped = WrappedData4(assetCodeData)
        let asset = AssetXDR.alphanum4(Alpha4XDR(assetCode: assetCodeWrapped, issuer: issuerPublicKey))

        let op = SetTrustLineFlagsOpXDR(
            accountID: accountPublicKey,
            asset: asset,
            setFlags: TrustLineFlags.TRUSTLINE_CLAWBACK_ENABLED_FLAG,
            clearFlags: TrustLineFlags.AUTHORIZED_FLAG | TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG
        )

        guard let base64 = op.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try SetTrustLineFlagsOpXDR(xdr: base64)

        XCTAssertEqual(decoded.accountID.accountId, testAccountIdString)
        XCTAssertEqual(decoded.setFlags, TrustLineFlags.TRUSTLINE_CLAWBACK_ENABLED_FLAG)
        XCTAssertEqual(decoded.clearFlags, TrustLineFlags.AUTHORIZED_FLAG | TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG)
    }

    func testSetTrustLineFlagsOpXDRAllFlagsCombinations() throws {
        let accountPublicKey = try PublicKey(accountId: testAccountIdString)
        let asset = AssetXDR.native

        // Test all flags combined
        let allFlags = TrustLineFlags.AUTHORIZED_FLAG |
                       TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG |
                       TrustLineFlags.TRUSTLINE_CLAWBACK_ENABLED_FLAG

        let op1 = SetTrustLineFlagsOpXDR(
            accountID: accountPublicKey,
            asset: asset,
            setFlags: allFlags,
            clearFlags: 0
        )

        let encoded1 = try XDREncoder.encode(op1)
        let decoded1 = try XDRDecoder.decode(SetTrustLineFlagsOpXDR.self, data: encoded1)

        XCTAssertEqual(decoded1.setFlags, allFlags)
        XCTAssertEqual(decoded1.clearFlags, 0)

        // Test clear all flags
        let op2 = SetTrustLineFlagsOpXDR(
            accountID: accountPublicKey,
            asset: asset,
            setFlags: 0,
            clearFlags: allFlags
        )

        let encoded2 = try XDREncoder.encode(op2)
        let decoded2 = try XDRDecoder.decode(SetTrustLineFlagsOpXDR.self, data: encoded2)

        XCTAssertEqual(decoded2.setFlags, 0)
        XCTAssertEqual(decoded2.clearFlags, allFlags)

        // Test individual flags
        let flagCombinations: [(UInt32, UInt32)] = [
            (TrustLineFlags.AUTHORIZED_FLAG, 0),
            (0, TrustLineFlags.AUTHORIZED_FLAG),
            (TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG, TrustLineFlags.AUTHORIZED_FLAG),
            (TrustLineFlags.TRUSTLINE_CLAWBACK_ENABLED_FLAG, TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG)
        ]

        for (setFlags, clearFlags) in flagCombinations {
            let op = SetTrustLineFlagsOpXDR(
                accountID: accountPublicKey,
                asset: asset,
                setFlags: setFlags,
                clearFlags: clearFlags
            )

            let encoded = try XDREncoder.encode(op)
            let decoded = try XDRDecoder.decode(SetTrustLineFlagsOpXDR.self, data: encoded)

            XCTAssertEqual(decoded.setFlags, setFlags)
            XCTAssertEqual(decoded.clearFlags, clearFlags)
        }
    }

    // MARK: - SetTrustLineFlagsResultXDR Tests

    func testSetTrustLineFlagsResultXDRSuccess() throws {
        let result = SetTrustLineFlagsResultXDR.success(SetTrustLineFlagsResultCode.success.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsResultXDR.self, data: encoded)

        switch decoded {
        case .success(let code):
            XCTAssertEqual(code, SetTrustLineFlagsResultCode.success.rawValue)
        case .empty:
            XCTFail("Expected success case, got empty")
        }
    }

    func testSetTrustLineFlagsResultXDRMalformed() throws {
        let result = SetTrustLineFlagsResultXDR.empty(SetTrustLineFlagsResultCode.malformed.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case, got success")
        case .empty(let code):
            XCTAssertEqual(code, SetTrustLineFlagsResultCode.malformed.rawValue)
        }
    }

    func testSetTrustLineFlagsResultXDRNoTrustLine() throws {
        let result = SetTrustLineFlagsResultXDR.empty(SetTrustLineFlagsResultCode.noTrustLine.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case, got success")
        case .empty(let code):
            XCTAssertEqual(code, SetTrustLineFlagsResultCode.noTrustLine.rawValue)
        }
    }

    func testSetTrustLineFlagsResultXDRCantRevoke() throws {
        let result = SetTrustLineFlagsResultXDR.empty(SetTrustLineFlagsResultCode.cantRevoke.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case, got success")
        case .empty(let code):
            XCTAssertEqual(code, SetTrustLineFlagsResultCode.cantRevoke.rawValue)
        }
    }

    // MARK: - Additional Result Code Tests

    func testSetTrustLineFlagsResultXDRInvalidState() throws {
        let result = SetTrustLineFlagsResultXDR.empty(SetTrustLineFlagsResultCode.invalidState.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case, got success")
        case .empty(let code):
            XCTAssertEqual(code, SetTrustLineFlagsResultCode.invalidState.rawValue)
        }
    }

    func testSetTrustLineFlagsResultXDRLowReserve() throws {
        let result = SetTrustLineFlagsResultXDR.empty(SetTrustLineFlagsResultCode.lowReserve.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case, got success")
        case .empty(let code):
            XCTAssertEqual(code, SetTrustLineFlagsResultCode.lowReserve.rawValue)
        }
    }

    func testSetTrustLineFlagsResultXDRRoundTripBase64() throws {
        let result = SetTrustLineFlagsResultXDR.success(SetTrustLineFlagsResultCode.success.rawValue)

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try SetTrustLineFlagsResultXDR(xdr: base64)

        switch decoded {
        case .success(let code):
            XCTAssertEqual(code, SetTrustLineFlagsResultCode.success.rawValue)
        case .empty:
            XCTFail("Expected success case")
        }
    }

    // MARK: - Result Code Enum Tests

    func testSetTrustLineFlagsResultCodeRawValues() {
        XCTAssertEqual(SetTrustLineFlagsResultCode.success.rawValue, 0)
        XCTAssertEqual(SetTrustLineFlagsResultCode.malformed.rawValue, -1)
        XCTAssertEqual(SetTrustLineFlagsResultCode.noTrustLine.rawValue, -2)
        XCTAssertEqual(SetTrustLineFlagsResultCode.cantRevoke.rawValue, -3)
        XCTAssertEqual(SetTrustLineFlagsResultCode.invalidState.rawValue, -4)
        XCTAssertEqual(SetTrustLineFlagsResultCode.lowReserve.rawValue, -5)
    }

    func testTrustLineFlagsValues() {
        XCTAssertEqual(TrustLineFlags.AUTHORIZED_FLAG, 1)
        XCTAssertEqual(TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG, 2)
        XCTAssertEqual(TrustLineFlags.TRUSTLINE_CLAWBACK_ENABLED_FLAG, 4)

        // Test flag combinations using bitwise OR
        let combinedFlags = TrustLineFlags.AUTHORIZED_FLAG | TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG
        XCTAssertEqual(combinedFlags, 3)

        let allFlags = TrustLineFlags.AUTHORIZED_FLAG |
                       TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG |
                       TrustLineFlags.TRUSTLINE_CLAWBACK_ENABLED_FLAG
        XCTAssertEqual(allFlags, 7)
    }
}
