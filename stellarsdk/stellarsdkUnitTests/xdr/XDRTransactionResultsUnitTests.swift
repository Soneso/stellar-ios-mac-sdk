//
//  XDRTransactionResultsUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Tests for transaction-level and operation-level result types that are
/// NOT yet covered by existing test files.  Focuses on:
///
///   - TransactionResultBodyXDR  feeBumpInnerSuccess / feeBumpInnerFailed
///   - TransactionResultXDRExtXDR / InnerTransactionResultXDRExtXDR
///   - InnerTransactionResultBodyXDR  all error codes (round-trip)
///   - InnerTransactionResultXDR  with various error bodies
///   - ManageOfferSuccessResultOfferXDR  (created / updated / deleted)
///   - ManageOfferSuccessResultXDR  with claimed offers
///   - ClaimOfferAtomV0XDR  via generated initializer
///   - ClaimLiquidityAtomXDR  via generated initializer
///   - SetOptionsResultXDR.authRevocableRequired
///   - RestoreFootprintResultXDR.insufficientRefundableFee
///   - OperationResultXDRTrXDR  standalone round-trip
///   - TransactionResultXDR  feeBump variant round-trip
class XDRTransactionResultsUnitTests: XCTestCase {

    // MARK: - Helpers

    private func testPublicKey() throws -> PublicKey {
        return try XDRTestHelpers.publicKey()
    }

    private func testOfferEntry() throws -> OfferEntryXDR {
        let pk = try testPublicKey()
        return OfferEntryXDR(
            sellerID: pk,
            offerID: 99887,
            selling: .native,
            buying: .native,
            amount: 5000000,
            price: PriceXDR(n: 3, d: 2),
            flags: 0
        )
    }

    // MARK: - TransactionResultXDRExtXDR

    func testTransactionResultXDRExtXDRVoidRoundTrip() throws {
        let ext = TransactionResultXDRExtXDR.void

        let encoded = try XDREncoder.encode(ext)
        let decoded = try XDRDecoder.decode(TransactionResultXDRExtXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 0)
    }

    // MARK: - InnerTransactionResultXDRExtXDR

    func testInnerTransactionResultXDRExtXDRVoidRoundTrip() throws {
        let ext = InnerTransactionResultXDRExtXDR.void

        let encoded = try XDREncoder.encode(ext)
        let decoded = try XDRDecoder.decode(InnerTransactionResultXDRExtXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 0)
    }

    // MARK: - InnerTransactionResultBodyXDR  All Error Codes

    func testInnerTransactionResultBodyXDRAllErrorCodesRoundTrip() throws {
        let errorCases: [(InnerTransactionResultBodyXDR, TransactionResultCode, String)] = [
            (.tooEarly,              .tooEarly,              "tooEarly"),
            (.tooLate,               .tooLate,               "tooLate"),
            (.missingOperation,      .missingOperation,      "missingOperation"),
            (.badSeq,                .badSeq,                "badSeq"),
            (.badAuth,               .badAuth,               "badAuth"),
            (.insufficientBalance,   .insufficientBalance,   "insufficientBalance"),
            (.noAccount,             .noAccount,             "noAccount"),
            (.insufficientFee,       .insufficientFee,       "insufficientFee"),
            (.badAuthExtra,          .badAuthExtra,          "badAuthExtra"),
            (.internalError,         .internalError,         "internalError"),
            (.notSupported,          .notSupported,          "notSupported"),
            (.badSponsorship,        .badSponsorship,        "badSponsorship"),
            (.badMinSeqAgeOrGap,     .badMinSeqAgeOrGap,     "badMinSeqAgeOrGap"),
            (.malformed,             .malformed,             "malformed"),
            (.sorobanInvalid,        .sorobanInvalid,        "sorobanInvalid"),
        ]

        for (body, expectedCode, label) in errorCases {
            let encoded = try XDREncoder.encode(body)
            let decoded = try XDRDecoder.decode(InnerTransactionResultBodyXDR.self, data: encoded)

            XCTAssertEqual(decoded.type(), expectedCode.rawValue, "type() mismatch for \(label)")

            // Re-encode and compare bytes to verify fidelity
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded, "byte mismatch for \(label)")
        }
    }

    func testInnerTransactionResultBodyXDRSuccessWithOperationResults() throws {
        let opResult = OperationResultXDR.tr(.createAccountResult(.success))
        let body = InnerTransactionResultBodyXDR.success([opResult])

        let encoded = try XDREncoder.encode(body)
        let decoded = try XDRDecoder.decode(InnerTransactionResultBodyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), TransactionResultCode.success.rawValue)
        if case .success(let results) = decoded {
            XCTAssertEqual(results.count, 1)
        } else {
            XCTFail("Expected success case")
        }
    }

    func testInnerTransactionResultBodyXDRFailedWithOperationResults() throws {
        let opResult = OperationResultXDR.badAuth
        let body = InnerTransactionResultBodyXDR.failed([opResult])

        let encoded = try XDREncoder.encode(body)
        let decoded = try XDRDecoder.decode(InnerTransactionResultBodyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), TransactionResultCode.failed.rawValue)
        if case .failed(let results) = decoded {
            XCTAssertEqual(results.count, 1)
        } else {
            XCTFail("Expected failed case")
        }
    }

    // MARK: - InnerTransactionResultXDR  Full Struct with Various Bodies

    func testInnerTransactionResultXDRWithAllErrorBodies() throws {
        let errorBodies: [(InnerTransactionResultBodyXDR, String)] = [
            (.tooEarly,             "tooEarly"),
            (.badSeq,               "badSeq"),
            (.insufficientBalance,  "insufficientBalance"),
            (.noAccount,            "noAccount"),
            (.sorobanInvalid,       "sorobanInvalid"),
        ]

        for (body, label) in errorBodies {
            let inner = InnerTransactionResultXDR(feeCharged: 250, result: body)

            let encoded = try XDREncoder.encode(inner)
            let decoded = try XDRDecoder.decode(InnerTransactionResultXDR.self, data: encoded)

            XCTAssertEqual(decoded.feeCharged, 250, "feeCharged mismatch for \(label)")
            XCTAssertEqual(decoded.code, TransactionResultCode(rawValue: body.type()), "code mismatch for \(label)")
        }
    }

    func testInnerTransactionResultXDRWithOperationResults() throws {
        let opResult = OperationResultXDR.tr(.paymentResult(.success))
        let inner = InnerTransactionResultXDR(feeCharged: 777, result: .success([opResult]))

        let encoded = try XDREncoder.encode(inner)
        let decoded = try XDRDecoder.decode(InnerTransactionResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.feeCharged, 777)
        XCTAssertEqual(decoded.code, .success)
        if case .success(let results) = decoded.result {
            XCTAssertEqual(results.count, 1)
        } else {
            XCTFail("Expected success body")
        }
    }

    // MARK: - TransactionResultBodyXDR  feeBumpInnerSuccess / feeBumpInnerFailed

    func testTransactionResultBodyXDRFeeBumpInnerSuccess() throws {
        let hashData = Data(repeating: 0xAB, count: 32)
        let hash = WrappedData32(hashData)
        let innerResult = InnerTransactionResultXDR(feeCharged: 300, result: .success([]))
        let pair = InnerTransactionResultPair(hash: hash, result: innerResult)

        let body = TransactionResultBodyXDR.feeBumpInnerSuccess(pair)

        let encoded = try XDREncoder.encode(body)
        let decoded = try XDRDecoder.decode(TransactionResultBodyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), TransactionResultCode.feeBumpInnerSuccess.rawValue)

        if case .feeBumpInnerSuccess(let decodedPair) = decoded {
            XCTAssertEqual(decodedPair.hash.wrapped, hashData)
            XCTAssertEqual(decodedPair.result.feeCharged, 300)
            XCTAssertEqual(decodedPair.result.code, .success)
        } else {
            XCTFail("Expected feeBumpInnerSuccess case")
        }
    }

    func testTransactionResultBodyXDRFeeBumpInnerFailed() throws {
        let hashData = Data(repeating: 0xCD, count: 32)
        let hash = WrappedData32(hashData)
        let opResult = OperationResultXDR.badAuth
        let innerResult = InnerTransactionResultXDR(feeCharged: 450, result: .failed([opResult]))
        let pair = InnerTransactionResultPair(hash: hash, result: innerResult)

        let body = TransactionResultBodyXDR.feeBumpInnerFailed(pair)

        let encoded = try XDREncoder.encode(body)
        let decoded = try XDRDecoder.decode(TransactionResultBodyXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), TransactionResultCode.feeBumpInnerFailed.rawValue)

        if case .feeBumpInnerFailed(let decodedPair) = decoded {
            XCTAssertEqual(decodedPair.hash.wrapped, hashData)
            XCTAssertEqual(decodedPair.result.feeCharged, 450)
            XCTAssertEqual(decodedPair.result.code, .failed)
            if case .failed(let ops) = decodedPair.result.result {
                XCTAssertEqual(ops.count, 1)
                XCTAssertEqual(ops[0].type(), OperationResultCode.badAuth.rawValue)
            } else {
                XCTFail("Expected failed body inside inner result")
            }
        } else {
            XCTFail("Expected feeBumpInnerFailed case")
        }
    }

    // MARK: - TransactionResultXDR  feeBump Variant Round-Trip

    func testTransactionResultXDRFeeBumpInnerSuccessFullRoundTrip() throws {
        let hashData = Data(repeating: 0xEF, count: 32)
        let hash = WrappedData32(hashData)
        let innerResult = InnerTransactionResultXDR(feeCharged: 600, result: .success([]))
        let pair = InnerTransactionResultPair(hash: hash, result: innerResult)

        let txResult = TransactionResultXDR(
            feeCharged: 1200,
            result: .feeBumpInnerSuccess(pair)
        )

        let encoded = try XDREncoder.encode(txResult)
        let decoded = try XDRDecoder.decode(TransactionResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.feeCharged, 1200)
        XCTAssertEqual(decoded.code, .feeBumpInnerSuccess)

        if case .feeBumpInnerSuccess(let decodedPair) = decoded.result {
            XCTAssertEqual(decodedPair.hash.wrapped, hashData)
            XCTAssertEqual(decodedPair.result.feeCharged, 600)
        } else {
            XCTFail("Expected feeBumpInnerSuccess result body")
        }
    }

    func testTransactionResultXDRFeeBumpInnerFailedFullRoundTrip() throws {
        let hashData = Data(repeating: 0x11, count: 32)
        let hash = WrappedData32(hashData)
        let innerResult = InnerTransactionResultXDR(feeCharged: 100, result: .badSeq)
        let pair = InnerTransactionResultPair(hash: hash, result: innerResult)

        let txResult = TransactionResultXDR(
            feeCharged: 500,
            result: .feeBumpInnerFailed(pair)
        )

        let encoded = try XDREncoder.encode(txResult)
        let decoded = try XDRDecoder.decode(TransactionResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.feeCharged, 500)
        XCTAssertEqual(decoded.code, .feeBumpInnerFailed)

        if case .feeBumpInnerFailed(let decodedPair) = decoded.result {
            XCTAssertEqual(decodedPair.hash.wrapped, hashData)
            XCTAssertEqual(decodedPair.result.code, .badSeq)
        } else {
            XCTFail("Expected feeBumpInnerFailed result body")
        }
    }

    func testTransactionResultXDRFeeBumpInnerSuccessBase64() throws {
        let hashData = Data(repeating: 0x22, count: 32)
        let hash = WrappedData32(hashData)
        let innerResult = InnerTransactionResultXDR(feeCharged: 200, result: .success([]))
        let pair = InnerTransactionResultPair(hash: hash, result: innerResult)

        let txResult = TransactionResultXDR(
            feeCharged: 800,
            result: .feeBumpInnerSuccess(pair)
        )

        guard let base64 = txResult.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try TransactionResultXDR.fromXdr(base64: base64)

        XCTAssertEqual(decoded.feeCharged, 800)
        XCTAssertEqual(decoded.code, .feeBumpInnerSuccess)
    }

    // MARK: - ManageOfferSuccessResultOfferXDR  Round-Trip

    func testManageOfferSuccessResultOfferXDRCreated() throws {
        let offer = try testOfferEntry()
        let offerResult = ManageOfferSuccessResultOfferXDR.created(offer)

        let encoded = try XDREncoder.encode(offerResult)
        let decoded = try XDRDecoder.decode(ManageOfferSuccessResultOfferXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ManageOfferEffect.created.rawValue)

        if case .created(let decodedOffer) = decoded {
            XCTAssertEqual(decodedOffer.offerID, 99887)
            XCTAssertEqual(decodedOffer.amount, 5000000)
        } else {
            XCTFail("Expected created case")
        }
    }

    func testManageOfferSuccessResultOfferXDRUpdated() throws {
        let offer = try testOfferEntry()
        let offerResult = ManageOfferSuccessResultOfferXDR.updated(offer)

        let encoded = try XDREncoder.encode(offerResult)
        let decoded = try XDRDecoder.decode(ManageOfferSuccessResultOfferXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ManageOfferEffect.updated.rawValue)

        if case .updated(let decodedOffer) = decoded {
            XCTAssertEqual(decodedOffer.offerID, 99887)
            XCTAssertEqual(decodedOffer.amount, 5000000)
        } else {
            XCTFail("Expected updated case")
        }
    }

    func testManageOfferSuccessResultOfferXDRDeleted() throws {
        let offerResult = ManageOfferSuccessResultOfferXDR.deleted

        let encoded = try XDREncoder.encode(offerResult)
        let decoded = try XDRDecoder.decode(ManageOfferSuccessResultOfferXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ManageOfferEffect.deleted.rawValue)

        if case .deleted = decoded {
            // expected
        } else {
            XCTFail("Expected deleted case")
        }
    }

    // MARK: - ManageOfferSuccessResultXDR  With Claimed Offers

    func testManageOfferSuccessResultXDRWithClaimedOfferOrderBook() throws {
        let pk = try testPublicKey()
        let claimAtom = ClaimOfferAtomXDR(
            sellerId: pk,
            offerId: 44556,
            assetSold: .native,
            amountSold: 1500000,
            assetBought: .native,
            amountBought: 750000
        )
        let claimed = ClaimAtomXDR.orderBook(claimAtom)

        let offer = try testOfferEntry()
        let successResult = ManageOfferSuccessResultXDR(
            offersClaimed: [claimed],
            offer: .created(offer)
        )

        let encoded = try XDREncoder.encode(successResult)
        let decoded = try XDRDecoder.decode(ManageOfferSuccessResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.offersClaimed.count, 1)
        if case .orderBook(let atom) = decoded.offersClaimed[0] {
            XCTAssertEqual(atom.offerId, 44556)
            XCTAssertEqual(atom.amountSold, 1500000)
            XCTAssertEqual(atom.amountBought, 750000)
        } else {
            XCTFail("Expected orderBook claim atom")
        }

        if case .created(let decodedOffer) = decoded.offer {
            XCTAssertEqual(decodedOffer.offerID, 99887)
        } else {
            XCTFail("Expected created offer")
        }
    }

    func testManageOfferSuccessResultXDRWithDeletedOffer() throws {
        let successResult = ManageOfferSuccessResultXDR(
            offersClaimed: [],
            offer: .deleted
        )

        let encoded = try XDREncoder.encode(successResult)
        let decoded = try XDRDecoder.decode(ManageOfferSuccessResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.offersClaimed.count, 0)
        XCTAssertEqual(decoded.offer.type(), ManageOfferEffect.deleted.rawValue)
    }

    func testManageOfferSuccessResultXDRWithUpdatedOffer() throws {
        let offer = try testOfferEntry()
        let successResult = ManageOfferSuccessResultXDR(
            offersClaimed: [],
            offer: .updated(offer)
        )

        let encoded = try XDREncoder.encode(successResult)
        let decoded = try XDRDecoder.decode(ManageOfferSuccessResultXDR.self, data: encoded)

        if case .updated(let decodedOffer) = decoded.offer {
            XCTAssertEqual(decodedOffer.offerID, 99887)
            XCTAssertEqual(decodedOffer.amount, 5000000)
        } else {
            XCTFail("Expected updated offer")
        }
    }

    // MARK: - ClaimOfferAtomV0XDR  Via Generated Initializer

    func testClaimOfferAtomV0XDRRoundTrip() throws {
        let sellerKey = XDRTestHelpers.wrappedData32()
        let atom = ClaimOfferAtomV0XDR(
            sellerEd25519: sellerKey,
            offerId: 12345,
            assetSold: .native,
            amountSold: 2000000,
            assetBought: .native,
            amountBought: 1000000
        )

        let encoded = try XDREncoder.encode(atom)
        let decoded = try XDRDecoder.decode(ClaimOfferAtomV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.sellerEd25519.wrapped, sellerKey.wrapped)
        XCTAssertEqual(decoded.offerId, 12345)
        XCTAssertEqual(decoded.amountSold, 2000000)
        XCTAssertEqual(decoded.amountBought, 1000000)
    }

    func testClaimAtomXDRV0ViaInitializer() throws {
        let sellerKey = XDRTestHelpers.wrappedData32()
        let v0Atom = ClaimOfferAtomV0XDR(
            sellerEd25519: sellerKey,
            offerId: 77777,
            assetSold: .native,
            amountSold: 3000000,
            assetBought: .native,
            amountBought: 1500000
        )
        let claimAtom = ClaimAtomXDR.v0(v0Atom)

        let encoded = try XDREncoder.encode(claimAtom)
        let decoded = try XDRDecoder.decode(ClaimAtomXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ClaimAtomType.v0.rawValue)
        if case .v0(let decodedAtom) = decoded {
            XCTAssertEqual(decodedAtom.offerId, 77777)
            XCTAssertEqual(decodedAtom.amountSold, 3000000)
            XCTAssertEqual(decodedAtom.amountBought, 1500000)
        } else {
            XCTFail("Expected v0 case")
        }
    }

    // MARK: - ClaimLiquidityAtomXDR  Via Generated Initializer

    func testClaimLiquidityAtomXDRRoundTrip() throws {
        let poolId = WrappedData32(Data(repeating: 0xBB, count: 32))
        let atom = ClaimLiquidityAtomXDR(
            liquidityPoolID: poolId,
            assetSold: .native,
            amountSold: 4000000,
            assetBought: .native,
            amountBought: 2000000
        )

        let encoded = try XDREncoder.encode(atom)
        let decoded = try XDRDecoder.decode(ClaimLiquidityAtomXDR.self, data: encoded)

        XCTAssertEqual(decoded.liquidityPoolID.wrapped, poolId.wrapped)
        XCTAssertEqual(decoded.amountSold, 4000000)
        XCTAssertEqual(decoded.amountBought, 2000000)
    }

    func testClaimAtomXDRLiquidityPoolViaInitializer() throws {
        let poolId = WrappedData32(Data(repeating: 0xCC, count: 32))
        let lpAtom = ClaimLiquidityAtomXDR(
            liquidityPoolID: poolId,
            assetSold: .native,
            amountSold: 6000000,
            assetBought: .native,
            amountBought: 3000000
        )
        let claimAtom = ClaimAtomXDR.liquidityPool(lpAtom)

        let encoded = try XDREncoder.encode(claimAtom)
        let decoded = try XDRDecoder.decode(ClaimAtomXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ClaimAtomType.liquidityPool.rawValue)
        if case .liquidityPool(let decodedAtom) = decoded {
            XCTAssertEqual(decodedAtom.liquidityPoolID.wrapped, poolId.wrapped)
            XCTAssertEqual(decodedAtom.amountSold, 6000000)
            XCTAssertEqual(decodedAtom.amountBought, 3000000)
        } else {
            XCTFail("Expected liquidityPool case")
        }
    }

    // MARK: - SetOptionsResultXDR.authRevocableRequired

    func testSetOptionsResultXDRAuthRevocableRequired() throws {
        let result = SetOptionsResultXDR.authRevocableRequired

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetOptionsResultXDR.self, data: encoded)

        if case .authRevocableRequired = decoded {
            // expected
        } else {
            XCTFail("Expected authRevocableRequired case")
        }
    }

    func testSetOptionsResultCodeAuthRevocableRequiredRawValue() {
        XCTAssertEqual(SetOptionsResultCode.authRevocableRequired.rawValue, -10)
    }

    // MARK: - RestoreFootprintResultXDR.insufficientRefundableFee

    func testRestoreFootprintResultXDRInsufficientRefundableFee() throws {
        let result = RestoreFootprintResultXDR.insufficientRefundableFee

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(RestoreFootprintResultXDR.self, data: encoded)

        if case .insufficientRefundableFee = decoded {
            // expected
        } else {
            XCTFail("Expected insufficientRefundableFee case")
        }
    }

    func testRestoreFootprintResultCodeInsufficientRefundableFeeRawValue() {
        XCTAssertEqual(RestoreFootprintResultCode.insufficientRefundableFee.rawValue, -3)
    }

    // MARK: - OperationResultXDRTrXDR  Standalone Round-Trip

    func testOperationResultXDRTrXDRCreateAccountRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.createAccountResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.accountCreated.rawValue)
    }

    func testOperationResultXDRTrXDRPaymentRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.paymentResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.payment.rawValue)
    }

    func testOperationResultXDRTrXDRPathPaymentStrictReceiveRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.pathPaymentStrictReceiveResult(.malformed)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.pathPayment.rawValue)
    }

    func testOperationResultXDRTrXDRManageSellOfferRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.manageSellOfferResult(.malformed)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.manageSellOffer.rawValue)
    }

    func testOperationResultXDRTrXDRCreatePassiveSellOfferRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.createPassiveSellOfferResult(.malformed)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.createPassiveSellOffer.rawValue)
    }

    func testOperationResultXDRTrXDRSetOptionsRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.setOptionsResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.setOptions.rawValue)
    }

    func testOperationResultXDRTrXDRChangeTrustRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.changeTrustResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.changeTrust.rawValue)
    }

    func testOperationResultXDRTrXDRAllowTrustRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.allowTrustResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.allowTrust.rawValue)
    }

    func testOperationResultXDRTrXDRAccountMergeRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.accountMergeResult(.sourceAccountBalance(9999999))

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.accountMerge.rawValue)
        if case .accountMergeResult(let mergeResult) = decoded {
            if case .sourceAccountBalance(let balance) = mergeResult {
                XCTAssertEqual(balance, 9999999)
            } else {
                XCTFail("Expected sourceAccountBalance")
            }
        } else {
            XCTFail("Expected accountMergeResult")
        }
    }

    func testOperationResultXDRTrXDRInflationRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.inflationResult(.notTime)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.inflation.rawValue)
    }

    func testOperationResultXDRTrXDRManageDataRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.manageDataResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.manageData.rawValue)
    }

    func testOperationResultXDRTrXDRBumpSequenceRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.bumpSeqResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.bumpSequence.rawValue)
    }

    func testOperationResultXDRTrXDRManageBuyOfferRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.manageBuyOfferResult(.malformed)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.manageBuyOffer.rawValue)
    }

    func testOperationResultXDRTrXDRPathPaymentStrictSendRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.pathPaymentStrictSendResult(.malformed)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.pathPaymentStrictSend.rawValue)
    }

    func testOperationResultXDRTrXDRCreateClaimableBalanceRoundTrip() throws {
        let balanceId = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xDD, count: 32)))
        let tr = OperationResultXDRTrXDR.createClaimableBalanceResult(.balanceID(balanceId))

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.createClaimableBalance.rawValue)
    }

    func testOperationResultXDRTrXDRClaimClaimableBalanceRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.claimClaimableBalanceResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.claimClaimableBalance.rawValue)
    }

    func testOperationResultXDRTrXDRBeginSponsoringRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.beginSponsoringFutureReservesResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.beginSponsoringFutureReserves.rawValue)
    }

    func testOperationResultXDRTrXDREndSponsoringRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.endSponsoringFutureReservesResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.endSponsoringFutureReserves.rawValue)
    }

    func testOperationResultXDRTrXDRRevokeSponsorshipRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.revokeSponsorshipResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.revokeSponsorship.rawValue)
    }

    func testOperationResultXDRTrXDRClawbackRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.clawbackResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.clawback.rawValue)
    }

    func testOperationResultXDRTrXDRClawbackClaimableBalanceRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.clawbackClaimableBalanceResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.clawbackClaimableBalance.rawValue)
    }

    func testOperationResultXDRTrXDRSetTrustLineFlagsRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.setTrustLineFlagsResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.setTrustLineFlags.rawValue)
    }

    func testOperationResultXDRTrXDRLiquidityPoolDepositRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.liquidityPoolDepositResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.liquidityPoolDeposit.rawValue)
    }

    func testOperationResultXDRTrXDRLiquidityPoolWithdrawRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.liquidityPoolWithdrawResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.liquidityPoolWithdraw.rawValue)
    }

    func testOperationResultXDRTrXDRInvokeHostFunctionRoundTrip() throws {
        let hash = WrappedData32(Data(repeating: 0xAA, count: 32))
        let tr = OperationResultXDRTrXDR.invokeHostFunctionResult(.success(hash))

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.invokeHostFunction.rawValue)
        if case .invokeHostFunctionResult(let ihfResult) = decoded {
            if case .success(let decodedHash) = ihfResult {
                XCTAssertEqual(decodedHash.wrapped, Data(repeating: 0xAA, count: 32))
            } else {
                XCTFail("Expected success inside invokeHostFunctionResult")
            }
        } else {
            XCTFail("Expected invokeHostFunctionResult")
        }
    }

    func testOperationResultXDRTrXDRExtendFootprintTTLRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.extendFootprintTTLResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.extendFootprintTTL.rawValue)
    }

    func testOperationResultXDRTrXDRRestoreFootprintRoundTrip() throws {
        let tr = OperationResultXDRTrXDR.restoreFootprintResult(.success)

        let encoded = try XDREncoder.encode(tr)
        let decoded = try XDRDecoder.decode(OperationResultXDRTrXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), OperationType.restoreFootprint.rawValue)
    }

    // MARK: - TransactionResultBodyXDR  Remaining Void Cases Round-Trip

    func testTransactionResultBodyXDRAllVoidCasesRoundTrip() throws {
        let voidCases: [(TransactionResultBodyXDR, TransactionResultCode, String)] = [
            (.tooEarly,            .tooEarly,            "tooEarly"),
            (.tooLate,             .tooLate,             "tooLate"),
            (.missingOperation,    .missingOperation,    "missingOperation"),
            (.badSeq,              .badSeq,              "badSeq"),
            (.badAuth,             .badAuth,             "badAuth"),
            (.insufficientBalance, .insufficientBalance, "insufficientBalance"),
            (.noAccount,           .noAccount,           "noAccount"),
            (.insufficientFee,     .insufficientFee,     "insufficientFee"),
            (.badAuthExtra,        .badAuthExtra,        "badAuthExtra"),
            (.internalError,       .internalError,       "internalError"),
            (.notSupported,        .notSupported,        "notSupported"),
            (.badSponsorship,      .badSponsorship,      "badSponsorship"),
            (.badMinSeqAgeOrGap,   .badMinSeqAgeOrGap,   "badMinSeqAgeOrGap"),
            (.malformed,           .malformed,           "malformed"),
            (.sorobanInvalid,      .sorobanInvalid,      "sorobanInvalid"),
        ]

        for (body, expectedCode, label) in voidCases {
            let encoded = try XDREncoder.encode(body)
            let decoded = try XDRDecoder.decode(TransactionResultBodyXDR.self, data: encoded)

            XCTAssertEqual(decoded.type(), expectedCode.rawValue, "type() mismatch for \(label)")
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded, "byte mismatch for \(label)")
        }
    }

    // MARK: - ManageOfferSuccessResultXDR  With Liquidity Pool Claim Atom

    func testManageOfferSuccessResultXDRWithLiquidityPoolClaim() throws {
        let poolId = WrappedData32(Data(repeating: 0xDD, count: 32))
        let lpAtom = ClaimLiquidityAtomXDR(
            liquidityPoolID: poolId,
            assetSold: .native,
            amountSold: 5000000,
            assetBought: .native,
            amountBought: 2500000
        )
        let claimed = ClaimAtomXDR.liquidityPool(lpAtom)

        let offer = try testOfferEntry()
        let successResult = ManageOfferSuccessResultXDR(
            offersClaimed: [claimed],
            offer: .updated(offer)
        )

        let encoded = try XDREncoder.encode(successResult)
        let decoded = try XDRDecoder.decode(ManageOfferSuccessResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.offersClaimed.count, 1)
        if case .liquidityPool(let decodedAtom) = decoded.offersClaimed[0] {
            XCTAssertEqual(decodedAtom.liquidityPoolID.wrapped, poolId.wrapped)
            XCTAssertEqual(decodedAtom.amountSold, 5000000)
        } else {
            XCTFail("Expected liquidityPool claim atom")
        }

        if case .updated(let decodedOffer) = decoded.offer {
            XCTAssertEqual(decodedOffer.offerID, 99887)
        } else {
            XCTFail("Expected updated offer")
        }
    }

    // MARK: - TransactionResultXDR  With Multiple Operation Results

    func testTransactionResultXDRSuccessWithMultipleOperations() throws {
        let op1 = OperationResultXDR.tr(.createAccountResult(.success))
        let op2 = OperationResultXDR.tr(.paymentResult(.success))
        let op3 = OperationResultXDR.tr(.changeTrustResult(.success))

        let txResult = TransactionResultXDR(
            feeCharged: 300,
            result: .success([op1, op2, op3])
        )

        let encoded = try XDREncoder.encode(txResult)
        let decoded = try XDRDecoder.decode(TransactionResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.feeCharged, 300)
        XCTAssertEqual(decoded.code, .success)

        if case .success(let ops) = decoded.result {
            XCTAssertEqual(ops.count, 3)
            XCTAssertEqual(ops[0].type(), OperationResultCode.inner.rawValue)
            XCTAssertEqual(ops[1].type(), OperationResultCode.inner.rawValue)
            XCTAssertEqual(ops[2].type(), OperationResultCode.inner.rawValue)
        } else {
            XCTFail("Expected success result body")
        }
    }

    func testTransactionResultXDRFailedWithMultipleOperations() throws {
        let op1 = OperationResultXDR.tr(.createAccountResult(.success))
        let op2 = OperationResultXDR.badAuth

        let txResult = TransactionResultXDR(
            feeCharged: 200,
            result: .failed([op1, op2])
        )

        let encoded = try XDREncoder.encode(txResult)
        let decoded = try XDRDecoder.decode(TransactionResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.feeCharged, 200)
        XCTAssertEqual(decoded.code, .failed)

        if case .failed(let ops) = decoded.result {
            XCTAssertEqual(ops.count, 2)
            XCTAssertEqual(ops[0].type(), OperationResultCode.inner.rawValue)
            XCTAssertEqual(ops[1].type(), OperationResultCode.badAuth.rawValue)
        } else {
            XCTFail("Expected failed result body")
        }
    }

    // MARK: - InnerTransactionResultPair  More Thorough Round-Trip

    func testInnerTransactionResultPairWithFailedInner() throws {
        let hashData = Data(repeating: 0x99, count: 32)
        let hash = WrappedData32(hashData)

        let opResult = OperationResultXDR.noAccount
        let innerResult = InnerTransactionResultXDR(feeCharged: 350, result: .failed([opResult]))
        let pair = InnerTransactionResultPair(hash: hash, result: innerResult)

        let encoded = try XDREncoder.encode(pair)
        let decoded = try XDRDecoder.decode(InnerTransactionResultPair.self, data: encoded)

        XCTAssertEqual(decoded.hash.wrapped, hashData)
        XCTAssertEqual(decoded.result.feeCharged, 350)
        XCTAssertEqual(decoded.result.code, .failed)

        if case .failed(let ops) = decoded.result.result {
            XCTAssertEqual(ops.count, 1)
            XCTAssertEqual(ops[0].type(), OperationResultCode.noAccount.rawValue)
        } else {
            XCTFail("Expected failed inner result body")
        }
    }

    func testInnerTransactionResultPairBase64() throws {
        let hashData = Data(repeating: 0x55, count: 32)
        let hash = WrappedData32(hashData)
        let innerResult = InnerTransactionResultXDR(feeCharged: 100, result: .tooLate)
        let pair = InnerTransactionResultPair(hash: hash, result: innerResult)

        guard let base64 = pair.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try InnerTransactionResultPair(xdr: base64)

        XCTAssertEqual(decoded.hash.wrapped, hashData)
        XCTAssertEqual(decoded.result.feeCharged, 100)
        XCTAssertEqual(decoded.result.code, .tooLate)
    }

    // MARK: - ManageOfferResultXDR  Success With Updated Offer

    func testManageOfferResultXDRSuccessWithUpdatedOffer() throws {
        let offer = try testOfferEntry()
        let successResult = ManageOfferSuccessResultXDR(
            offersClaimed: [],
            offer: .updated(offer)
        )
        let result = ManageOfferResultXDR.success(successResult)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ManageOfferResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ManageOfferResultCode.success.rawValue)

        if case .success(let decodedSuccess) = decoded {
            if case .updated(let decodedOffer) = decodedSuccess.offer {
                XCTAssertEqual(decodedOffer.offerID, 99887)
                XCTAssertEqual(decodedOffer.amount, 5000000)
            } else {
                XCTFail("Expected updated offer")
            }
        } else {
            XCTFail("Expected success result")
        }
    }

    func testManageOfferResultXDRSuccessWithDeletedOffer() throws {
        let successResult = ManageOfferSuccessResultXDR(
            offersClaimed: [],
            offer: .deleted
        )
        let result = ManageOfferResultXDR.success(successResult)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ManageOfferResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ManageOfferResultCode.success.rawValue)

        if case .success(let decodedSuccess) = decoded {
            XCTAssertEqual(decodedSuccess.offer.type(), ManageOfferEffect.deleted.rawValue)
        } else {
            XCTFail("Expected success result")
        }
    }

    // MARK: - OperationResultXDR  With Specific Inner Results via .tr

    func testOperationResultXDRTrWithSetOptionsAuthRevocableRequired() throws {
        let result = OperationResultXDR.tr(.setOptionsResult(.authRevocableRequired))

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(OperationResultXDR.self, data: encoded)

        if case .tr(let tr) = decoded {
            if case .setOptionsResult(let soResult) = tr {
                if case .authRevocableRequired = soResult {
                    // expected
                } else {
                    XCTFail("Expected authRevocableRequired inside setOptionsResult")
                }
            } else {
                XCTFail("Expected setOptionsResult inside .tr")
            }
        } else {
            XCTFail("Expected .tr case")
        }
    }

    func testOperationResultXDRTrWithRestoreFootprintInsufficientFee() throws {
        let result = OperationResultXDR.tr(.restoreFootprintResult(.insufficientRefundableFee))

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(OperationResultXDR.self, data: encoded)

        if case .tr(let tr) = decoded {
            if case .restoreFootprintResult(let rfResult) = tr {
                if case .insufficientRefundableFee = rfResult {
                    // expected
                } else {
                    XCTFail("Expected insufficientRefundableFee inside restoreFootprintResult")
                }
            } else {
                XCTFail("Expected restoreFootprintResult inside .tr")
            }
        } else {
            XCTFail("Expected .tr case")
        }
    }

    // MARK: - ClaimOfferAtomV0XDR  With Non-Native Asset

    func testClaimOfferAtomV0XDRWithRealisticValues() throws {
        let sellerKey = WrappedData32(Data(repeating: 0x42, count: 32))
        let atom = ClaimOfferAtomV0XDR(
            sellerEd25519: sellerKey,
            offerId: 999888777,
            assetSold: .native,
            amountSold: 50000000,  // 5 XLM
            assetBought: .native,
            amountBought: 25000000  // 2.5 XLM
        )

        let encoded = try XDREncoder.encode(atom)
        let decoded = try XDRDecoder.decode(ClaimOfferAtomV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.sellerEd25519.wrapped, sellerKey.wrapped)
        XCTAssertEqual(decoded.offerId, 999888777)
        XCTAssertEqual(decoded.amountSold, 50000000)
        XCTAssertEqual(decoded.amountBought, 25000000)
    }

    // MARK: - Edge Cases

    func testTransactionResultXDRWithZeroFeeCharged() throws {
        let txResult = TransactionResultXDR(
            feeCharged: 0,
            result: .success([])
        )

        let encoded = try XDREncoder.encode(txResult)
        let decoded = try XDRDecoder.decode(TransactionResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.feeCharged, 0)
        XCTAssertEqual(decoded.code, .success)
    }

    func testTransactionResultXDRWithMaxFeeCharged() throws {
        let txResult = TransactionResultXDR(
            feeCharged: Int64.max,
            result: .badSeq
        )

        let encoded = try XDREncoder.encode(txResult)
        let decoded = try XDRDecoder.decode(TransactionResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.feeCharged, Int64.max)
        XCTAssertEqual(decoded.code, .badSeq)
    }

    func testInnerTransactionResultXDRWithZeroFee() throws {
        let inner = InnerTransactionResultXDR(feeCharged: 0, result: .success([]))

        let encoded = try XDREncoder.encode(inner)
        let decoded = try XDRDecoder.decode(InnerTransactionResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.feeCharged, 0)
        XCTAssertEqual(decoded.code, .success)
    }

    func testClaimOfferAtomV0XDRWithBoundaryOfferId() throws {
        let sellerKey = XDRTestHelpers.wrappedData32()
        let atom = ClaimOfferAtomV0XDR(
            sellerEd25519: sellerKey,
            offerId: Int64.max,
            assetSold: .native,
            amountSold: 1,
            assetBought: .native,
            amountBought: 1
        )

        let encoded = try XDREncoder.encode(atom)
        let decoded = try XDRDecoder.decode(ClaimOfferAtomV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.offerId, Int64.max)
    }
}
