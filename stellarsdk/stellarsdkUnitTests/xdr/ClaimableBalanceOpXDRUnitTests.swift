//
//  ClaimableBalanceOpXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class ClaimableBalanceOpXDRUnitTests: XCTestCase {

    // MARK: - Test Constants

    private let testAccountId1 = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
    private let testAccountId2 = "GBXGQJWVLWOYHFLVTKWV5FGHA3LNYY2JQKM7OAJAUEQFU6LPCSEFVXON"
    private let testBalanceIdHex = "da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be"

    // MARK: - CreateClaimableBalanceOpXDR Tests

    func testCreateClaimableBalanceOpXDREncodeDecode() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let claimantV0 = ClaimantV0XDR(accountID: publicKey, predicate: .claimPredicateUnconditional)
        let claimant = ClaimantXDR.claimantTypeV0(claimantV0)

        let op = CreateClaimableBalanceOpXDR(
            asset: .native,
            amount: 10000000000,
            claimants: [claimant]
        )

        let encoded = try XDREncoder.encode(op)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(CreateClaimableBalanceOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.amount, 10000000000)
        XCTAssertEqual(decoded.claimants.count, 1)
    }

    func testCreateClaimableBalanceOpXDRWithNativeAsset() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let claimantV0 = ClaimantV0XDR(accountID: publicKey, predicate: .claimPredicateUnconditional)
        let claimant = ClaimantXDR.claimantTypeV0(claimantV0)

        let op = CreateClaimableBalanceOpXDR(
            asset: .native,
            amount: 5000000000,
            claimants: [claimant]
        )

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceOpXDR.self, data: encoded)

        var isNativeAsset = false
        if case .native = decoded.asset {
            isNativeAsset = true
        }
        XCTAssertTrue(isNativeAsset, "Expected native asset")
        XCTAssertEqual(decoded.amount, 5000000000)
    }

    func testCreateClaimableBalanceOpXDRWithCreditAlphanum4() throws {
        let issuerKeyPair = try KeyPair(accountId: testAccountId1)
        let claimantPublicKey = try PublicKey(accountId: testAccountId2)

        let asset = try AssetXDR(assetCode: "USD", issuer: issuerKeyPair)
        let claimantV0 = ClaimantV0XDR(accountID: claimantPublicKey, predicate: .claimPredicateUnconditional)
        let claimant = ClaimantXDR.claimantTypeV0(claimantV0)

        let op = CreateClaimableBalanceOpXDR(
            asset: asset,
            amount: 1000000000,
            claimants: [claimant]
        )

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.asset.assetCode, "USD")
        XCTAssertEqual(decoded.asset.issuer?.accountId, testAccountId1)
        XCTAssertEqual(decoded.asset.type(), AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
        XCTAssertEqual(decoded.amount, 1000000000)
    }

    func testCreateClaimableBalanceOpXDRWithCreditAlphanum12() throws {
        let issuerKeyPair = try KeyPair(accountId: testAccountId1)
        let claimantPublicKey = try PublicKey(accountId: testAccountId2)

        let asset = try AssetXDR(assetCode: "TESTASSET12", issuer: issuerKeyPair)
        let claimantV0 = ClaimantV0XDR(accountID: claimantPublicKey, predicate: .claimPredicateUnconditional)
        let claimant = ClaimantXDR.claimantTypeV0(claimantV0)

        let op = CreateClaimableBalanceOpXDR(
            asset: asset,
            amount: 2500000000,
            claimants: [claimant]
        )

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.asset.assetCode, "TESTASSET12")
        XCTAssertEqual(decoded.asset.issuer?.accountId, testAccountId1)
        XCTAssertEqual(decoded.asset.type(), AssetType.ASSET_TYPE_CREDIT_ALPHANUM12)
        XCTAssertEqual(decoded.amount, 2500000000)
    }

    func testCreateClaimableBalanceOpXDRWithSingleClaimant() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let claimantV0 = ClaimantV0XDR(accountID: publicKey, predicate: .claimPredicateUnconditional)
        let claimant = ClaimantXDR.claimantTypeV0(claimantV0)

        let op = CreateClaimableBalanceOpXDR(
            asset: .native,
            amount: 7500000000,
            claimants: [claimant]
        )

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.claimants.count, 1)

        switch decoded.claimants[0] {
        case .claimantTypeV0(let v0):
            XCTAssertEqual(v0.accountID.accountId, testAccountId1)
        }
    }

    func testCreateClaimableBalanceOpXDRWithMultipleClaimants() throws {
        let publicKey1 = try PublicKey(accountId: testAccountId1)
        let publicKey2 = try PublicKey(accountId: testAccountId2)

        let claimantV0_1 = ClaimantV0XDR(accountID: publicKey1, predicate: .claimPredicateUnconditional)
        let claimantV0_2 = ClaimantV0XDR(accountID: publicKey2, predicate: .claimPredicateUnconditional)

        let claimant1 = ClaimantXDR.claimantTypeV0(claimantV0_1)
        let claimant2 = ClaimantXDR.claimantTypeV0(claimantV0_2)

        let op = CreateClaimableBalanceOpXDR(
            asset: .native,
            amount: 20000000000,
            claimants: [claimant1, claimant2]
        )

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.claimants.count, 2)

        switch decoded.claimants[0] {
        case .claimantTypeV0(let v0):
            XCTAssertEqual(v0.accountID.accountId, testAccountId1)
        }

        switch decoded.claimants[1] {
        case .claimantTypeV0(let v0):
            XCTAssertEqual(v0.accountID.accountId, testAccountId2)
        }
    }

    func testCreateClaimableBalanceOpXDRWithUnconditionalPredicate() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let predicate = ClaimPredicateXDR.claimPredicateUnconditional
        let claimantV0 = ClaimantV0XDR(accountID: publicKey, predicate: predicate)
        let claimant = ClaimantXDR.claimantTypeV0(claimantV0)

        let op = CreateClaimableBalanceOpXDR(
            asset: .native,
            amount: 3000000000,
            claimants: [claimant]
        )

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceOpXDR.self, data: encoded)

        var isUnconditionalPredicate = false
        if case .claimantTypeV0(let v0) = decoded.claimants[0] {
            if case .claimPredicateUnconditional = v0.predicate {
                isUnconditionalPredicate = true
            }
        }
        XCTAssertTrue(isUnconditionalPredicate, "Expected unconditional predicate")
    }

    func testCreateClaimableBalanceOpXDRWithTimePredicates() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)

        // Test with absolute time predicate
        let absTimePredicate = ClaimPredicateXDR.claimPredicateBeforeAbsTime(1704067200)
        let claimantV0Abs = ClaimantV0XDR(accountID: publicKey, predicate: absTimePredicate)
        let claimantAbs = ClaimantXDR.claimantTypeV0(claimantV0Abs)

        let opAbs = CreateClaimableBalanceOpXDR(
            asset: .native,
            amount: 1000000000,
            claimants: [claimantAbs]
        )

        let encodedAbs = try XDREncoder.encode(opAbs)
        let decodedAbs = try XDRDecoder.decode(CreateClaimableBalanceOpXDR.self, data: encodedAbs)

        switch decodedAbs.claimants[0] {
        case .claimantTypeV0(let v0):
            switch v0.predicate {
            case .claimPredicateBeforeAbsTime(let time):
                XCTAssertEqual(time, 1704067200)
            default:
                XCTFail("Expected beforeAbsTime predicate")
            }
        }

        // Test with relative time predicate
        let relTimePredicate = ClaimPredicateXDR.claimPredicateBeforeRelTime(86400)
        let claimantV0Rel = ClaimantV0XDR(accountID: publicKey, predicate: relTimePredicate)
        let claimantRel = ClaimantXDR.claimantTypeV0(claimantV0Rel)

        let opRel = CreateClaimableBalanceOpXDR(
            asset: .native,
            amount: 2000000000,
            claimants: [claimantRel]
        )

        let encodedRel = try XDREncoder.encode(opRel)
        let decodedRel = try XDRDecoder.decode(CreateClaimableBalanceOpXDR.self, data: encodedRel)

        switch decodedRel.claimants[0] {
        case .claimantTypeV0(let v0):
            switch v0.predicate {
            case .claimPredicateBeforeRelTime(let time):
                XCTAssertEqual(time, 86400)
            default:
                XCTFail("Expected beforeRelTime predicate")
            }
        }
    }

    // MARK: - ClaimClaimableBalanceOpXDR Tests

    func testClaimClaimableBalanceOpXDREncodeDecode() throws {
        let balanceId = try ClaimableBalanceIDXDR(claimableBalanceId: testBalanceIdHex)
        let op = ClaimClaimableBalanceOpXDR(balanceID: balanceId)

        let encoded = try XDREncoder.encode(op)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(ClaimClaimableBalanceOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.balanceID.type(), ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)
    }

    func testClaimClaimableBalanceOpXDRWithV0BalanceId() throws {
        let balanceId = try ClaimableBalanceIDXDR(claimableBalanceId: testBalanceIdHex)
        let op = ClaimClaimableBalanceOpXDR(balanceID: balanceId)

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(ClaimClaimableBalanceOpXDR.self, data: encoded)

        switch decoded.balanceID {
        case .claimableBalanceIDTypeV0(let data):
            XCTAssertEqual(data.wrapped.count, 32)
        }
    }

    func testClaimClaimableBalanceOpXDRRoundTrip() throws {
        let balanceId = try ClaimableBalanceIDXDR(claimableBalanceId: testBalanceIdHex)
        let op = ClaimClaimableBalanceOpXDR(balanceID: balanceId)

        guard let base64 = op.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try ClaimClaimableBalanceOpXDR(xdr: base64)

        XCTAssertEqual(decoded.balanceID.claimableBalanceIdString, balanceId.claimableBalanceIdString)
    }

    func testClaimClaimableBalanceOpXDRFromBase64() throws {
        let balanceId = try ClaimableBalanceIDXDR(claimableBalanceId: testBalanceIdHex)
        let op = ClaimClaimableBalanceOpXDR(balanceID: balanceId)

        guard let base64 = op.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        XCTAssertFalse(base64.isEmpty)

        let decoded = try ClaimClaimableBalanceOpXDR(xdr: base64)

        XCTAssertNotNil(decoded.balanceID)
        XCTAssertEqual(decoded.balanceID.type(), ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)
    }

    // MARK: - CreateClaimableBalanceResultXDR Tests

    func testCreateClaimableBalanceResultXDRSuccess() throws {
        let balanceId = try ClaimableBalanceIDXDR(claimableBalanceId: testBalanceIdHex)
        let result = CreateClaimableBalanceResultXDR.success(
            CreateClaimableBalanceResultCode.success.rawValue,
            balanceId
        )

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .success(let code, let decodedBalanceId):
            XCTAssertEqual(code, CreateClaimableBalanceResultCode.success.rawValue)
            XCTAssertEqual(decodedBalanceId.claimableBalanceIdString, balanceId.claimableBalanceIdString)
        case .empty:
            XCTFail("Expected success case, got empty")
        }
    }

    func testCreateClaimableBalanceResultXDRMalformed() throws {
        let result = CreateClaimableBalanceResultXDR.empty(CreateClaimableBalanceResultCode.malformed.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case, got success")
        case .empty(let code):
            XCTAssertEqual(code, CreateClaimableBalanceResultCode.malformed.rawValue)
        }
    }

    // MARK: - ClaimClaimableBalanceResultXDR Tests

    func testClaimClaimableBalanceResultXDRSuccess() throws {
        let result = ClaimClaimableBalanceResultXDR.success(ClaimClaimableBalanceResultCode.success.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClaimClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .success(let code):
            XCTAssertEqual(code, ClaimClaimableBalanceResultCode.success.rawValue)
        case .empty:
            XCTFail("Expected success case, got empty")
        }
    }

    func testClaimClaimableBalanceResultXDRDoesNotExist() throws {
        let result = ClaimClaimableBalanceResultXDR.empty(ClaimClaimableBalanceResultCode.doesNotExist.rawValue)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClaimClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected empty case, got success")
        case .empty(let code):
            XCTAssertEqual(code, ClaimClaimableBalanceResultCode.doesNotExist.rawValue)
        }
    }

    // MARK: - Additional Claimant and Predicate Tests

    func testClaimantV0XDREncodeDecode() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let predicate = ClaimPredicateXDR.claimPredicateUnconditional
        let claimantV0 = ClaimantV0XDR(accountID: publicKey, predicate: predicate)

        let encoded = try XDREncoder.encode(claimantV0)
        let decoded = try XDRDecoder.decode(ClaimantV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.accountID.accountId, testAccountId1)
    }

    func testClaimPredicateAndOrCombination() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)

        // Create AND predicate with two time-based conditions
        let pred1 = ClaimPredicateXDR.claimPredicateBeforeAbsTime(1704067200)
        let pred2 = ClaimPredicateXDR.claimPredicateBeforeRelTime(86400)
        let andPredicate = ClaimPredicateXDR.claimPredicateAnd([pred1, pred2])

        let claimantV0 = ClaimantV0XDR(accountID: publicKey, predicate: andPredicate)
        let claimant = ClaimantXDR.claimantTypeV0(claimantV0)

        let op = CreateClaimableBalanceOpXDR(
            asset: .native,
            amount: 5000000000,
            claimants: [claimant]
        )

        let encoded = try XDREncoder.encode(op)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceOpXDR.self, data: encoded)

        switch decoded.claimants[0] {
        case .claimantTypeV0(let v0):
            switch v0.predicate {
            case .claimPredicateAnd(let predicates):
                XCTAssertEqual(predicates.count, 2)
            default:
                XCTFail("Expected AND predicate")
            }
        }
    }
}
