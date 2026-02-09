//
//  ClawbackOpXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class ClawbackOpXDRUnitTests: XCTestCase {

    // MARK: - Test Constants

    private let testAccountId1 = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
    private let testAccountId2 = "GBXGQJWVLWOYHFLVTKWV5FGHA3LNYY2JQKM7OAJAUEQFU6LPCSEFVXON"
    private let testBalanceIdHex = "da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be"

    // MARK: - ClawbackOpXDR Tests

    func testClawbackOpXDREncodeDecode() throws {
        let issuerKeyPair = try KeyPair(accountId: testAccountId1)
        let asset = try AssetXDR(assetCode: "USD", issuer: issuerKeyPair)

        let fromPublicKey = try PublicKey(accountId: testAccountId2)
        let fromAccount = MuxedAccountXDR.ed25519(fromPublicKey.bytes)

        let clawbackAmount: Int64 = 10000000000 // 1000 in stroops

        let op = ClawbackOpXDR(asset: asset, from: fromAccount, amount: clawbackAmount)

        let encoded = try XDREncoder.encode(op)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(ClawbackOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.amount, clawbackAmount)
        XCTAssertEqual(decoded.from.ed25519AccountId, testAccountId2)
        XCTAssertEqual(decoded.asset.assetCode, "USD")
    }

    func testClawbackOpXDRWithMuxedAccount() throws {
        let issuerKeyPair = try KeyPair(accountId: testAccountId1)
        let asset = try AssetXDR(assetCode: "EUR", issuer: issuerKeyPair)

        let fromPublicKey = try PublicKey(accountId: testAccountId2)
        let muxedId: UInt64 = 12345678
        let muxedAccountMed = MuxedAccountMed25519XDR(id: muxedId, sourceAccountEd25519: fromPublicKey.bytes)
        let fromAccount = MuxedAccountXDR.med25519(muxedAccountMed)

        let clawbackAmount: Int64 = 5000000000

        let op = ClawbackOpXDR(asset: asset, from: fromAccount, amount: clawbackAmount)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(ClawbackOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.amount, clawbackAmount)
        XCTAssertEqual(decoded.from.ed25519AccountId, testAccountId2)
        XCTAssertEqual(decoded.from.id, muxedId)
        // KEY_TYPE_MUXED_ED25519 = 0x100 = 256
        XCTAssertEqual(decoded.from.type(), 0x100)
        XCTAssertEqual(decoded.asset.assetCode, "EUR")
    }

    func testClawbackOpXDRWithRegularAccount() throws {
        let issuerKeyPair = try KeyPair(accountId: testAccountId1)
        let asset = try AssetXDR(assetCode: "GBP", issuer: issuerKeyPair)

        let fromPublicKey = try PublicKey(accountId: testAccountId2)
        let fromAccount = MuxedAccountXDR.ed25519(fromPublicKey.bytes)

        let clawbackAmount: Int64 = 2500000000

        let op = ClawbackOpXDR(asset: asset, from: fromAccount, amount: clawbackAmount)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(ClawbackOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.amount, clawbackAmount)
        XCTAssertEqual(decoded.from.ed25519AccountId, testAccountId2)
        XCTAssertNil(decoded.from.id)
        // KEY_TYPE_ED25519 = 0
        XCTAssertEqual(decoded.from.type(), 0)
    }

    func testClawbackOpXDRWithAlphanum4Asset() throws {
        let issuerKeyPair = try KeyPair(accountId: testAccountId1)
        let asset = try AssetXDR(assetCode: "USDC", issuer: issuerKeyPair)

        let fromPublicKey = try PublicKey(accountId: testAccountId2)
        let fromAccount = MuxedAccountXDR.ed25519(fromPublicKey.bytes)

        let clawbackAmount: Int64 = 7500000000

        let op = ClawbackOpXDR(asset: asset, from: fromAccount, amount: clawbackAmount)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(ClawbackOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.asset.assetCode, "USDC")
        XCTAssertEqual(decoded.asset.issuer?.accountId, testAccountId1)
        XCTAssertEqual(decoded.asset.type(), AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
        XCTAssertEqual(decoded.amount, clawbackAmount)
    }

    func testClawbackOpXDRWithAlphanum12Asset() throws {
        let issuerKeyPair = try KeyPair(accountId: testAccountId1)
        let asset = try AssetXDR(assetCode: "CLAWBACKTOK", issuer: issuerKeyPair)

        let fromPublicKey = try PublicKey(accountId: testAccountId2)
        let fromAccount = MuxedAccountXDR.ed25519(fromPublicKey.bytes)

        let clawbackAmount: Int64 = 3000000000

        let op = ClawbackOpXDR(asset: asset, from: fromAccount, amount: clawbackAmount)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(ClawbackOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.asset.assetCode, "CLAWBACKTOK")
        XCTAssertEqual(decoded.asset.issuer?.accountId, testAccountId1)
        XCTAssertEqual(decoded.asset.type(), AssetType.ASSET_TYPE_CREDIT_ALPHANUM12)
        XCTAssertEqual(decoded.amount, clawbackAmount)
    }

    func testClawbackOpXDRRoundTrip() throws {
        let issuerKeyPair = try KeyPair(accountId: testAccountId1)
        let asset = try AssetXDR(assetCode: "CLAWTEST", issuer: issuerKeyPair)

        let fromPublicKey = try PublicKey(accountId: testAccountId2)
        let fromAccount = MuxedAccountXDR.ed25519(fromPublicKey.bytes)

        let clawbackAmount: Int64 = 15000000000

        let op = ClawbackOpXDR(asset: asset, from: fromAccount, amount: clawbackAmount)

        guard let base64 = op.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        XCTAssertFalse(base64.isEmpty)

        let decoded = try ClawbackOpXDR(xdr: base64)

        XCTAssertEqual(decoded.amount, clawbackAmount)
        XCTAssertEqual(decoded.from.ed25519AccountId, testAccountId2)
        XCTAssertEqual(decoded.asset.assetCode, "CLAWTEST")
        XCTAssertEqual(decoded.asset.issuer?.accountId, testAccountId1)
    }

    // MARK: - ClawbackClaimableBalanceOpXDR Tests

    func testClawbackClaimableBalanceOpXDREncodeDecode() throws {
        let balanceId = try ClaimableBalanceIDXDR(claimableBalanceId: testBalanceIdHex)
        let op = ClawbackClaimableBalanceOpXDR(claimableBalanceID: balanceId)

        let encoded = try XDREncoder.encode(op)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(ClawbackClaimableBalanceOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.claimableBalanceID.type(), ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)
        XCTAssertEqual(decoded.claimableBalanceID.claimableBalanceIdString, balanceId.claimableBalanceIdString)
    }

    func testClawbackClaimableBalanceOpXDRWithV0BalanceId() throws {
        let balanceId = try ClaimableBalanceIDXDR(claimableBalanceId: testBalanceIdHex)
        let op = ClawbackClaimableBalanceOpXDR(claimableBalanceID: balanceId)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(ClawbackClaimableBalanceOpXDR.self, data: encoded)

        switch decoded.claimableBalanceID {
        case .claimableBalanceIDTypeV0(let data):
            XCTAssertEqual(data.wrapped.count, 32)
        }
    }

    func testClawbackClaimableBalanceOpXDRRoundTrip() throws {
        let balanceId = try ClaimableBalanceIDXDR(claimableBalanceId: testBalanceIdHex)
        let op = ClawbackClaimableBalanceOpXDR(claimableBalanceID: balanceId)

        guard let base64 = op.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        XCTAssertFalse(base64.isEmpty)

        let decoded = try ClawbackClaimableBalanceOpXDR(xdr: base64)

        XCTAssertEqual(decoded.claimableBalanceID.claimableBalanceIdString, balanceId.claimableBalanceIdString)
    }

    // MARK: - ClawbackResultXDR Tests

    func testClawbackResultXDRSuccess() throws {
        let result = ClawbackResultXDR.success(ClawbackResultCode.success.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClawbackResultXDR.self, data: encoded)

        switch decoded {
        case .success(let code):
            XCTAssertEqual(code, ClawbackResultCode.success.rawValue)
        case .empty:
            XCTFail("Expected success case, got empty")
        }
    }

    func testClawbackResultXDRMalformed() throws {
        let result = ClawbackResultXDR.empty(ClawbackResultCode.malformed.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClawbackResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case, got success")
        case .empty(let code):
            XCTAssertEqual(code, ClawbackResultCode.malformed.rawValue)
        }
    }

    func testClawbackResultXDRNotClawbackEnabled() throws {
        let result = ClawbackResultXDR.empty(ClawbackResultCode.notClawbackEnabled.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClawbackResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case, got success")
        case .empty(let code):
            XCTAssertEqual(code, ClawbackResultCode.notClawbackEnabled.rawValue)
        }
    }

    // MARK: - ClawbackClaimableBalanceResultXDR Tests

    func testClawbackClaimableBalanceResultXDRSuccess() throws {
        let result = ClawbackClaimableBalanceResultXDR.success(ClawbackClaimableBalanceResultCode.success.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClawbackClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .success(let code):
            XCTAssertEqual(code, ClawbackClaimableBalanceResultCode.success.rawValue)
        case .empty:
            XCTFail("Expected success case, got empty")
        }
    }

    func testClawbackClaimableBalanceResultXDRDoesNotExist() throws {
        let result = ClawbackClaimableBalanceResultXDR.empty(ClawbackClaimableBalanceResultCode.doesNotExist.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClawbackClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case, got success")
        case .empty(let code):
            XCTAssertEqual(code, ClawbackClaimableBalanceResultCode.doesNotExist.rawValue)
        }
    }
}
