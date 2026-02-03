//
//  OperationXDRRemoteTestCase.swift
//  stellarsdkIntegrationTests
//
//  Created by Soneso on 02/02/2026.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class OperationXDRRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()

    func testGetTransactionXdr() async {
        let responseEnum = await sdk.transactions.getTransactions(limit:1)
        switch responseEnum {
        case .success(let transactionsResponse):
            if let response = transactionsResponse.records.first {
                guard let resultBody = response.transactionResult.resultBody else {
                    XCTFail()
                    return
                }
                switch resultBody {
                case .success(let operations):
                    self.validateOperation(operationXDR: operations.first!)
                default:
                    XCTFail()
                }
            }
        case .failure(_):
            XCTFail()
        }
    }

    func validateOperation(operationXDR: OperationResultXDR) {
        switch operationXDR {
        case .createAccount(let code, _):
            XCTAssertEqual(code, CreateAccountResultCode.success.rawValue)
        case .payment(let code, _):
            XCTAssertEqual(code, PaymentResultCode.success.rawValue)
        case .pathPayment(let code, _):
            XCTAssertEqual(code, PathPaymentResultCode.success.rawValue)
        case .manageSellOffer(let code, _):
            XCTAssertEqual(code, ManageOfferResultCode.success.rawValue)
        case .manageBuyOffer(let code, _):
            XCTAssertEqual(code, ManageOfferResultCode.success.rawValue)
        case .createPassiveSellOffer(let code, _):
            XCTAssertEqual(code, ManageOfferResultCode.success.rawValue)
        case .setOptions(let code, _):
            XCTAssertEqual(code, SetOptionsResultCode.success.rawValue)
        case .changeTrust(let code, _):
            XCTAssertEqual(code, ChangeTrustResultCode.success.rawValue)
        case .allowTrust(let code, _):
            XCTAssertEqual(code, AllowTrustResultCode.success.rawValue)
        case .accountMerge(let code, _):
            XCTAssertEqual(code, AccountMergeResultCode.success.rawValue)
        case .inflation(let code, _):
            XCTAssertEqual(code, InflationResultCode.success.rawValue)
        case .manageData(let code, _):
            XCTAssertEqual(code, ManageDataResultCode.success.rawValue)
        case .bumpSequence(let code, _):
            XCTAssertEqual(code, BumpSequenceResultCode.success.rawValue)
        case .pathPaymentStrictSend(let code, _):
            XCTAssertEqual(code, PathPaymentResultCode.success.rawValue)
        case .createClaimableBalance(let code, _):
            XCTAssertEqual(code, CreateClaimableBalanceResultCode.success.rawValue)
        case .claimClaimableBalance(let code, _):
            XCTAssertEqual(code, ClaimClaimableBalanceResultCode.success.rawValue)
        case .beginSponsoringFutureReserves(let code, _):
            XCTAssertEqual(code, BeginSponsoringFutureReservesResultCode.success.rawValue)
        case .endSponsoringFutureReserves(let code, _):
            XCTAssertEqual(code, EndSponsoringFutureReservesResultCode.success.rawValue)
        case .revokeSponsorship(let code, _):
            XCTAssertEqual(code, RevokeSponsorshipResultCode.success.rawValue)
        case .clawback(let code, _):
            XCTAssertEqual(code, ClawbackResultCode.success.rawValue)
        case .clawbackClaimableBalance(let code, _):
            XCTAssertEqual(code, ClawbackClaimableBalanceResultCode.success.rawValue)
        case .setTrustLineFlags(let code, _):
            XCTAssertEqual(code, SetTrustLineFlagsResultCode.success.rawValue)
        case .liquidityPoolDeposit(let code, _):
            XCTAssertEqual(code, LiquidityPoolDepositResulCode.success.rawValue)
        case .liquidityPoolWithdraw(let code, _):
            XCTAssertEqual(code, LiquidityPoolWithdrawResulCode.success.rawValue)
        case .invokeHostFunction(let code, _):
            XCTAssertEqual(code, InvokeHostFunctionResultCode.success.rawValue)
        case .extendFootprintTTL(let code, _):
            XCTAssertEqual(code, ExtendFootprintTTLResultCode.success.rawValue)
        case .restoreFootprint(let code, _):
            XCTAssertEqual(code, RestoreFootprintResultCode.success.rawValue)
        case .empty(let code):
            XCTAssertEqual(code, OperationResultCode.badAuth.rawValue)
        }

    }
}
