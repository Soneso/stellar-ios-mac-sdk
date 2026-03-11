//
//  XDROperationAndMetaResultsUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class XDROperationAndMetaResultsUnitTests: XCTestCase {

    // MARK: - EndSponsoringFutureReservesResultXDR Tests

    func testEndSponsoringFutureReservesResultXDRSuccess() throws {
        let result = EndSponsoringFutureReservesResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(EndSponsoringFutureReservesResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            break
        case .notSponsored:
            XCTFail("Expected success case, got notSponsored")
        }
    }

    func testEndSponsoringFutureReservesResultXDRNotSponsored() throws {
        let result = EndSponsoringFutureReservesResultXDR.notSponsored

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(EndSponsoringFutureReservesResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected notSponsored case, got success")
        case .notSponsored:
            break
        }
    }

    func testEndSponsoringFutureReservesResultXDRRoundTripBase64() throws {
        let result = EndSponsoringFutureReservesResultXDR.success

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try EndSponsoringFutureReservesResultXDR(xdr: base64)

        switch decoded {
        case .success:
            break
        case .notSponsored:
            XCTFail("Expected success case")
        }
    }

    // MARK: - ExtendFootprintTTLResultXDR Tests

    func testExtendFootprintTTLResultXDRSuccess() throws {
        let result = ExtendFootprintTTLResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ExtendFootprintTTLResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTAssertTrue(true, "Expected success case")
        default:
            XCTFail("Expected success case")
        }
    }

    func testExtendFootprintTTLResultXDRMalformed() throws {
        let result = ExtendFootprintTTLResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ExtendFootprintTTLResultXDR.self, data: encoded)

        switch decoded {
        case .malformed:
            XCTAssertTrue(true, "Expected malformed case")
        default:
            XCTFail("Expected malformed case")
        }
    }

    func testExtendFootprintTTLResultXDRResourceLimitExceeded() throws {
        let result = ExtendFootprintTTLResultXDR.resourceLimitExceeded

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ExtendFootprintTTLResultXDR.self, data: encoded)

        switch decoded {
        case .resourceLimitExceeded:
            XCTAssertTrue(true, "Expected resourceLimitExceeded case")
        default:
            XCTFail("Expected resourceLimitExceeded case")
        }
    }

    func testExtendFootprintTTLResultXDRInsufficientRefundableFee() throws {
        let result = ExtendFootprintTTLResultXDR.insufficientRefundableFee

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ExtendFootprintTTLResultXDR.self, data: encoded)

        switch decoded {
        case .insufficientRefundableFee:
            XCTAssertTrue(true, "Expected insufficientRefundableFee case")
        default:
            XCTFail("Expected insufficientRefundableFee case")
        }
    }

    func testExtendFootprintTTLResultXDRRoundTripBase64() throws {
        let result = ExtendFootprintTTLResultXDR.success

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try ExtendFootprintTTLResultXDR(xdr: base64)

        switch decoded {
        case .success:
            XCTAssertTrue(true, "Expected success case")
        default:
            XCTFail("Expected success case")
        }
    }

    // MARK: - HashIDPreimageXDR Tests

    func testHashIDPreimageXDROperationId() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        let operationId = OperationID(sourceAccount: publicKey, seqNum: 123456789, opNum: 1)
        let result = HashIDPreimageXDR.operationId(operationId)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(HashIDPreimageXDR.self, data: encoded)

        switch decoded {
        case .operationId(let decodedOpId):
            XCTAssertEqual(decodedOpId.seqNum, 123456789)
            XCTAssertEqual(decodedOpId.opNum, 1)
        default:
            XCTFail("Expected operationId case")
        }
    }

    func testHashIDPreimageXDRRevokeId() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        let poolIdData = Data(repeating: 0xAB, count: 32)
        let poolId = WrappedData32(poolIdData)
        let asset = AssetXDR.native

        let revokeId = RevokeID(sourceAccount: publicKey, seqNum: 987654321, opNum: 2, liquidityPoolID: poolId, asset: asset)
        let result = HashIDPreimageXDR.revokeId(revokeId)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(HashIDPreimageXDR.self, data: encoded)

        switch decoded {
        case .revokeId(let decodedRevokeId):
            XCTAssertEqual(decodedRevokeId.seqNum, 987654321)
            XCTAssertEqual(decodedRevokeId.opNum, 2)
        default:
            XCTFail("Expected revokeId case")
        }
    }

    func testHashIDPreimageXDRContractID() throws {
        let networkIdData = Data(repeating: 0xCD, count: 32)
        let networkId = WrappedData32(networkIdData)

        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let salt = WrappedData32(Data(repeating: 0xEF, count: 32))
        let contractIdPreimage = ContractIDPreimageXDR.fromAddress(ContractIDPreimageFromAddressXDR(address: SCAddressXDR.account(publicKey), salt: salt))

        let contractIdPreimageStruct = HashIDPreimageContractIDXDR(networkID: networkId, contractIDPreimage: contractIdPreimage)
        let result = HashIDPreimageXDR.contractID(contractIdPreimageStruct)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(HashIDPreimageXDR.self, data: encoded)

        switch decoded {
        case .contractID:
            XCTAssertTrue(true, "Expected contractID case")
        default:
            XCTFail("Expected contractID case")
        }
    }

    func testHashIDPreimageXDRRoundTripBase64() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        let operationId = OperationID(sourceAccount: publicKey, seqNum: 123456, opNum: 5)
        let result = HashIDPreimageXDR.operationId(operationId)

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try HashIDPreimageXDR(xdr: base64)

        switch decoded {
        case .operationId(let decodedOpId):
            XCTAssertEqual(decodedOpId.seqNum, 123456)
            XCTAssertEqual(decodedOpId.opNum, 5)
        default:
            XCTFail("Expected operationId case")
        }
    }

    // MARK: - InflationPayoutXDR Tests

    func testInflationPayoutXDREncodingDecoding() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let amount: Int64 = 5000000000

        let payout = InflationPayoutXDR(destination: publicKey, amount: amount)

        let encoded = try XDREncoder.encode(payout)
        let decoded = try XDRDecoder.decode(InflationPayoutXDR.self, data: encoded)

        XCTAssertEqual(decoded.destination.accountId, accountIdString)
        XCTAssertEqual(decoded.amount, amount)
    }

    func testInflationPayoutXDRRoundTripBase64() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let amount: Int64 = 1000000

        let payout = InflationPayoutXDR(destination: publicKey, amount: amount)

        guard let base64 = payout.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try InflationPayoutXDR(xdr: base64)

        XCTAssertEqual(decoded.destination.accountId, accountIdString)
        XCTAssertEqual(decoded.amount, amount)
    }

    // MARK: - InflationResultXDR Tests

    func testInflationResultXDRSuccess() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        let payout1 = InflationPayoutXDR(destination: publicKey, amount: 1000000)
        let payout2 = InflationPayoutXDR(destination: publicKey, amount: 2000000)
        let payouts = [payout1, payout2]

        let result = InflationResultXDR.payouts(payouts)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(InflationResultXDR.self, data: encoded)

        switch decoded {
        case .payouts(let decodedPayouts):
            XCTAssertEqual(decodedPayouts.count, 2)
            XCTAssertEqual(decodedPayouts[0].amount, 1000000)
            XCTAssertEqual(decodedPayouts[1].amount, 2000000)
        case .notTime:
            XCTFail("Expected payouts case")
        }
    }

    func testInflationResultXDRNotTime() throws {
        let result = InflationResultXDR.notTime

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(InflationResultXDR.self, data: encoded)

        switch decoded {
        case .payouts:
            XCTFail("Expected notTime case")
        case .notTime:
            break
        }
    }

    func testInflationResultXDRRoundTripBase64() throws {
        let result = InflationResultXDR.payouts([])

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try InflationResultXDR(xdr: base64)

        switch decoded {
        case .payouts(let payouts):
            XCTAssertEqual(payouts.count, 0)
        case .notTime:
            XCTFail("Expected payouts case")
        }
    }

    // MARK: - InvokeHostFunctionResultXDR Tests

    func testInvokeHostFunctionResultXDRSuccess() throws {
        let hashData = Data(repeating: 0xFF, count: 32)
        let hash = WrappedData32(hashData)

        let result = InvokeHostFunctionResultXDR.success(hash)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionResultXDR.self, data: encoded)

        switch decoded {
        case .success(let decodedHash):
            XCTAssertEqual(decodedHash.wrapped, hashData)
        default:
            XCTFail("Expected success case")
        }
    }

    func testInvokeHostFunctionResultXDRMalformed() throws {
        let result = InvokeHostFunctionResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionResultXDR.self, data: encoded)

        switch decoded {
        case .malformed:
            XCTAssertTrue(true, "Expected malformed case")
        default:
            XCTFail("Expected malformed case")
        }
    }

    func testInvokeHostFunctionResultXDRTrapped() throws {
        let result = InvokeHostFunctionResultXDR.trapped

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionResultXDR.self, data: encoded)

        switch decoded {
        case .trapped:
            XCTAssertTrue(true, "Expected trapped case")
        default:
            XCTFail("Expected trapped case")
        }
    }

    func testInvokeHostFunctionResultXDRResourceLimitExceeded() throws {
        let result = InvokeHostFunctionResultXDR.resourceLimitExceeded

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionResultXDR.self, data: encoded)

        switch decoded {
        case .resourceLimitExceeded:
            XCTAssertTrue(true, "Expected resourceLimitExceeded case")
        default:
            XCTFail("Expected resourceLimitExceeded case")
        }
    }

    func testInvokeHostFunctionResultXDREntryArchived() throws {
        let result = InvokeHostFunctionResultXDR.entryArchived

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionResultXDR.self, data: encoded)

        switch decoded {
        case .entryArchived:
            XCTAssertTrue(true, "Expected entryArchived case")
        default:
            XCTFail("Expected entryArchived case")
        }
    }

    func testInvokeHostFunctionResultXDRInsufficientRefundableFee() throws {
        let result = InvokeHostFunctionResultXDR.insufficientRefundableFee

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(InvokeHostFunctionResultXDR.self, data: encoded)

        switch decoded {
        case .insufficientRefundableFee:
            XCTAssertTrue(true, "Expected insufficientRefundableFee case")
        default:
            XCTFail("Expected insufficientRefundableFee case")
        }
    }

    func testInvokeHostFunctionResultXDRRoundTripBase64() throws {
        let hashData = Data(repeating: 0xAA, count: 32)
        let hash = WrappedData32(hashData)

        let result = InvokeHostFunctionResultXDR.success(hash)

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try InvokeHostFunctionResultXDR(xdr: base64)

        switch decoded {
        case .success(let decodedHash):
            XCTAssertEqual(decodedHash.wrapped, hashData)
        default:
            XCTFail("Expected success case")
        }
    }

    // MARK: - LiquidityPoolDepositResultXDR Tests

    func testLiquidityPoolDepositResultXDRSuccess() throws {
        let result = LiquidityPoolDepositResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(LiquidityPoolDepositResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testLiquidityPoolDepositResultXDRMalformed() throws {
        let result = LiquidityPoolDepositResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(LiquidityPoolDepositResultXDR.self, data: encoded)

        switch decoded {
        case .malformed:
            break
        default:
            XCTFail("Expected malformed case")
        }
    }

    func testLiquidityPoolDepositResultXDRNoTrust() throws {
        let result = LiquidityPoolDepositResultXDR.noTrust

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(LiquidityPoolDepositResultXDR.self, data: encoded)

        switch decoded {
        case .noTrust:
            break
        default:
            XCTFail("Expected noTrust case")
        }
    }

    func testLiquidityPoolDepositResultXDRRoundTripBase64() throws {
        let result = LiquidityPoolDepositResultXDR.success

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try LiquidityPoolDepositResultXDR(xdr: base64)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    // MARK: - LiquidityPoolWithdrawResultXDR Tests

    func testLiquidityPoolWithdrawResultXDRSuccess() throws {
        let result = LiquidityPoolWithdrawResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(LiquidityPoolWithdrawResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testLiquidityPoolWithdrawResultXDRMalformed() throws {
        let result = LiquidityPoolWithdrawResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(LiquidityPoolWithdrawResultXDR.self, data: encoded)

        switch decoded {
        case .malformed:
            break
        default:
            XCTFail("Expected malformed case")
        }
    }

    func testLiquidityPoolWithdrawResultXDRUnderMinimum() throws {
        let result = LiquidityPoolWithdrawResultXDR.underMinimum

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(LiquidityPoolWithdrawResultXDR.self, data: encoded)

        switch decoded {
        case .underMinimum:
            break
        default:
            XCTFail("Expected underMinimum case")
        }
    }

    func testLiquidityPoolWithdrawResultXDRRoundTripBase64() throws {
        let result = LiquidityPoolWithdrawResultXDR.success

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try LiquidityPoolWithdrawResultXDR(xdr: base64)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    // MARK: - ManageDataResultXDR Tests

    func testManageDataResultXDRSuccess() throws {
        let result = ManageDataResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ManageDataResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testManageDataResultXDRNotSupportedYet() throws {
        let result = ManageDataResultXDR.notSupportedYet

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ManageDataResultXDR.self, data: encoded)

        switch decoded {
        case .notSupportedYet:
            break
        default:
            XCTFail("Expected notSupportedYet case")
        }
    }

    func testManageDataResultXDRNameNotFound() throws {
        let result = ManageDataResultXDR.nameNotFound

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ManageDataResultXDR.self, data: encoded)

        switch decoded {
        case .nameNotFound:
            break
        default:
            XCTFail("Expected nameNotFound case")
        }
    }

    func testManageDataResultXDRLowReserve() throws {
        let result = ManageDataResultXDR.lowReserve

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ManageDataResultXDR.self, data: encoded)

        switch decoded {
        case .lowReserve:
            break
        default:
            XCTFail("Expected lowReserve case")
        }
    }

    func testManageDataResultXDRInvalidName() throws {
        let result = ManageDataResultXDR.invalidName

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ManageDataResultXDR.self, data: encoded)

        switch decoded {
        case .invalidName:
            break
        default:
            XCTFail("Expected invalidName case")
        }
    }

    func testManageDataResultXDRRoundTripBase64() throws {
        let result = ManageDataResultXDR.success

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try ManageDataResultXDR(xdr: base64)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    // MARK: - OperationMetaV2XDR Tests

    func testOperationMetaV2XDREncodingDecoding() throws {
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])

        // Create minimal contract event for testing
        let scVal = SCValXDR.u32(123)
        let eventBody = ContractEventBodyXDR.v0(ContractEventBodyV0XDR(topics: [], data: scVal))
        let contractEvent = ContractEventXDR(ext: .void, hash: nil, type: ContractEventType.system.rawValue, body: eventBody)

        let operationMeta = OperationMetaV2XDR(ext: .void, changes: changes, events: [contractEvent])

        let encoded = try XDREncoder.encode(operationMeta)
        let decoded = try XDRDecoder.decode(OperationMetaV2XDR.self, data: encoded)

        XCTAssertEqual(decoded.events.count, 1)
        XCTAssertEqual(decoded.events[0].type, ContractEventType.system.rawValue)
    }

    func testOperationMetaV2XDRWithEmptyEvents() throws {
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])
        let operationMeta = OperationMetaV2XDR(ext: .void, changes: changes, events: [])

        let encoded = try XDREncoder.encode(operationMeta)
        let decoded = try XDRDecoder.decode(OperationMetaV2XDR.self, data: encoded)

        XCTAssertEqual(decoded.events.count, 0)
    }

    func testOperationMetaV2XDRRoundTripBase64() throws {
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])
        let operationMeta = OperationMetaV2XDR(ext: .void, changes: changes, events: [])

        guard let base64 = operationMeta.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try OperationMetaV2XDR(xdr: base64)

        XCTAssertEqual(decoded.events.count, 0)
    }

    // MARK: - PaymentResultXDR Tests

    func testPaymentResultXDRSuccess() throws {
        let result = PaymentResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(PaymentResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testPaymentResultXDRMalformed() throws {
        let result = PaymentResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(PaymentResultXDR.self, data: encoded)

        switch decoded {
        case .malformed:
            break
        default:
            XCTFail("Expected malformed case")
        }
    }

    func testPaymentResultXDRUnderfunded() throws {
        let result = PaymentResultXDR.underfunded

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(PaymentResultXDR.self, data: encoded)

        switch decoded {
        case .underfunded:
            break
        default:
            XCTFail("Expected underfunded case")
        }
    }

    func testPaymentResultXDRNoDestination() throws {
        let result = PaymentResultXDR.noDestination

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(PaymentResultXDR.self, data: encoded)

        switch decoded {
        case .noDestination:
            break
        default:
            XCTFail("Expected noDestination case")
        }
    }

    func testPaymentResultXDRRoundTripBase64() throws {
        let result = PaymentResultXDR.success

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try PaymentResultXDR(xdr: base64)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    // MARK: - RestoreFootprintResultXDR Tests

    func testRestoreFootprintResultXDRSuccess() throws {
        let result = RestoreFootprintResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(RestoreFootprintResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTAssertTrue(true, "Expected success case")
        default:
            XCTFail("Expected success case")
        }
    }

    func testRestoreFootprintResultXDRMalformed() throws {
        let result = RestoreFootprintResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(RestoreFootprintResultXDR.self, data: encoded)

        switch decoded {
        case .malformed:
            XCTAssertTrue(true, "Expected malformed case")
        default:
            XCTFail("Expected malformed case")
        }
    }

    func testRestoreFootprintResultXDRResourceLimitExceeded() throws {
        let result = RestoreFootprintResultXDR.resourceLimitExceeded

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(RestoreFootprintResultXDR.self, data: encoded)

        switch decoded {
        case .resourceLimitExceeded:
            XCTAssertTrue(true, "Expected resourceLimitExceeded case")
        default:
            XCTFail("Expected resourceLimitExceeded case")
        }
    }

    func testRestoreFootprintResultXDRRoundTripBase64() throws {
        let result = RestoreFootprintResultXDR.success

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try RestoreFootprintResultXDR(xdr: base64)

        switch decoded {
        case .success:
            XCTAssertTrue(true, "Expected success case")
        default:
            XCTFail("Expected success case")
        }
    }

    // MARK: - RevokeSponsorshipResultXDR Tests

    func testRevokeSponsorshipResultXDRSuccess() throws {
        let result = RevokeSponsorshipResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testRevokeSponsorshipResultXDRDoesNotExist() throws {
        let result = RevokeSponsorshipResultXDR.doesNotExist

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipResultXDR.self, data: encoded)

        switch decoded {
        case .doesNotExist:
            break
        default:
            XCTFail("Expected doesNotExist case")
        }
    }

    func testRevokeSponsorshipResultXDRNotSponsor() throws {
        let result = RevokeSponsorshipResultXDR.notSponsor

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipResultXDR.self, data: encoded)

        switch decoded {
        case .notSponsor:
            break
        default:
            XCTFail("Expected notSponsor case")
        }
    }

    func testRevokeSponsorshipResultXDRLowReserve() throws {
        let result = RevokeSponsorshipResultXDR.lowReserve

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipResultXDR.self, data: encoded)

        switch decoded {
        case .lowReserve:
            break
        default:
            XCTFail("Expected lowReserve case")
        }
    }

    func testRevokeSponsorshipResultXDRMalformed() throws {
        let result = RevokeSponsorshipResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(RevokeSponsorshipResultXDR.self, data: encoded)

        switch decoded {
        case .malformed:
            break
        default:
            XCTFail("Expected malformed case")
        }
    }

    func testRevokeSponsorshipResultXDRRoundTripBase64() throws {
        let result = RevokeSponsorshipResultXDR.success

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try RevokeSponsorshipResultXDR(xdr: base64)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    // MARK: - SetTrustLineFlagsResultXDR Tests

    func testSetTrustLineFlagsResultXDRSuccess() throws {
        let result = SetTrustLineFlagsResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testSetTrustLineFlagsResultXDRMalformed() throws {
        let result = SetTrustLineFlagsResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsResultXDR.self, data: encoded)

        switch decoded {
        case .malformed:
            break
        default:
            XCTFail("Expected malformed case")
        }
    }

    func testSetTrustLineFlagsResultXDRNoTrustLine() throws {
        let result = SetTrustLineFlagsResultXDR.noTrustLine

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsResultXDR.self, data: encoded)

        switch decoded {
        case .noTrustLine:
            break
        default:
            XCTFail("Expected noTrustLine case")
        }
    }

    func testSetTrustLineFlagsResultXDRCantRevoke() throws {
        let result = SetTrustLineFlagsResultXDR.cantRevoke

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsResultXDR.self, data: encoded)

        switch decoded {
        case .cantRevoke:
            break
        default:
            XCTFail("Expected cantRevoke case")
        }
    }

    func testSetTrustLineFlagsResultXDRInvalidState() throws {
        let result = SetTrustLineFlagsResultXDR.invalidState

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsResultXDR.self, data: encoded)

        switch decoded {
        case .invalidState:
            break
        default:
            XCTFail("Expected invalidState case")
        }
    }

    func testSetTrustLineFlagsResultXDRLowReserve() throws {
        let result = SetTrustLineFlagsResultXDR.lowReserve

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SetTrustLineFlagsResultXDR.self, data: encoded)

        switch decoded {
        case .lowReserve:
            break
        default:
            XCTFail("Expected lowReserve case")
        }
    }

    func testSetTrustLineFlagsResultXDRRoundTripBase64() throws {
        let result = SetTrustLineFlagsResultXDR.success

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try SetTrustLineFlagsResultXDR(xdr: base64)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    // MARK: - TransactionEventXDR Tests

    func testTransactionEventXDRBeforeAllTxs() throws {
        let scVal = SCValXDR.u32(999)
        let eventBody = ContractEventBodyXDR.v0(ContractEventBodyV0XDR(topics: [], data: scVal))
        let contractEvent = ContractEventXDR(ext: .void, hash: nil, type: ContractEventType.system.rawValue, body: eventBody)

        let txEvent = TransactionEventXDR(stage: .beforeAllTxs, event: contractEvent)

        let encoded = try XDREncoder.encode(txEvent)
        let decoded = try XDRDecoder.decode(TransactionEventXDR.self, data: encoded)

        XCTAssertEqual(decoded.stage, .beforeAllTxs)
        XCTAssertEqual(decoded.event.type, ContractEventType.system.rawValue)
    }

    func testTransactionEventXDRAfterTx() throws {
        let scVal = SCValXDR.u32(111)
        let eventBody = ContractEventBodyXDR.v0(ContractEventBodyV0XDR(topics: [], data: scVal))
        let contractEvent = ContractEventXDR(ext: .void, hash: nil, type: ContractEventType.contract.rawValue, body: eventBody)

        let txEvent = TransactionEventXDR(stage: .afterTx, event: contractEvent)

        let encoded = try XDREncoder.encode(txEvent)
        let decoded = try XDRDecoder.decode(TransactionEventXDR.self, data: encoded)

        XCTAssertEqual(decoded.stage, .afterTx)
        XCTAssertEqual(decoded.event.type, ContractEventType.contract.rawValue)
    }

    func testTransactionEventXDRAfterAllTx() throws {
        let scVal = SCValXDR.u32(222)
        let eventBody = ContractEventBodyXDR.v0(ContractEventBodyV0XDR(topics: [], data: scVal))
        let contractEvent = ContractEventXDR(ext: .void, hash: nil, type: ContractEventType.diagnostic.rawValue, body: eventBody)

        let txEvent = TransactionEventXDR(stage: .afterAllTx, event: contractEvent)

        let encoded = try XDREncoder.encode(txEvent)
        let decoded = try XDRDecoder.decode(TransactionEventXDR.self, data: encoded)

        XCTAssertEqual(decoded.stage, .afterAllTx)
        XCTAssertEqual(decoded.event.type, ContractEventType.diagnostic.rawValue)
    }

    func testTransactionEventXDRRoundTripBase64() throws {
        let scVal = SCValXDR.u32(333)
        let eventBody = ContractEventBodyXDR.v0(ContractEventBodyV0XDR(topics: [], data: scVal))
        let contractEvent = ContractEventXDR(ext: .void, hash: nil, type: ContractEventType.system.rawValue, body: eventBody)

        let txEvent = TransactionEventXDR(stage: .afterTx, event: contractEvent)

        guard let base64 = txEvent.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try TransactionEventXDR(xdr: base64)

        XCTAssertEqual(decoded.stage, .afterTx)
        XCTAssertEqual(decoded.event.type, ContractEventType.system.rawValue)
    }

    // MARK: - TransactionMetaV1XDR Tests

    func testTransactionMetaV1XDREncodingDecoding() throws {
        // TransactionMetaV1XDR contains: txChanges (LedgerEntryChangesXDR) + operations array
        // Construct valid binary data: empty array (0x00000000) + empty operations array (0x00000000)
        let xdrData: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

        let decoded = try XDRDecoder.decode(TransactionMetaV1XDR.self, data: xdrData)
        XCTAssertNotNil(decoded.txChanges)

        // Re-encode and verify round-trip
        let encoded = try XDREncoder.encode(decoded)
        let reDecoded = try XDRDecoder.decode(TransactionMetaV1XDR.self, data: encoded)
        XCTAssertNotNil(reDecoded.txChanges)
    }

    func testTransactionMetaV1XDRRoundTripBase64() throws {
        // Empty TransactionMetaV1XDR: empty changes array + empty operations array
        let base64 = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]).base64EncodedString()

        let decoded = try TransactionMetaV1XDR(xdr: base64)
        XCTAssertNotNil(decoded.txChanges)

        guard let reEncoded = decoded.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let reDecoded = try TransactionMetaV1XDR(xdr: reEncoded)
        XCTAssertNotNil(reDecoded.txChanges)
    }

    // MARK: - TransactionMetaV3XDR Tests

    func testTransactionMetaV3XDREncodingDecoding() throws {
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])

        let metaV3 = TransactionMetaV3XDR(
            ext: .void,
            txChangesBefore: changes,
            operations: [],
            txChangesAfter: changes,
            sorobanMeta: nil
        )

        let encoded = try XDREncoder.encode(metaV3)
        let decoded = try XDRDecoder.decode(TransactionMetaV3XDR.self, data: encoded)

        XCTAssertNotNil(decoded.txChangesBefore)
        XCTAssertNotNil(decoded.txChangesAfter)
        XCTAssertNil(decoded.sorobanMeta)
    }

    func testTransactionMetaV3XDRWithSorobanMeta() throws {
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])
        let scVal = SCValXDR.u32(456)
        let sorobanMeta = SorobanTransactionMetaXDR(
            ext: .void,
            events: [],
            returnValue: scVal,
            diagnosticEvents: []
        )

        let metaV3 = TransactionMetaV3XDR(
            ext: .void,
            txChangesBefore: changes,
            operations: [],
            txChangesAfter: changes,
            sorobanMeta: sorobanMeta
        )

        let encoded = try XDREncoder.encode(metaV3)
        let decoded = try XDRDecoder.decode(TransactionMetaV3XDR.self, data: encoded)

        XCTAssertNotNil(decoded.sorobanMeta)
    }

    func testTransactionMetaV3XDRRoundTripBase64() throws {
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])

        let metaV3 = TransactionMetaV3XDR(
            ext: .void,
            txChangesBefore: changes,
            operations: [],
            txChangesAfter: changes,
            sorobanMeta: nil
        )

        guard let base64 = metaV3.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try TransactionMetaV3XDR(xdr: base64)

        XCTAssertNotNil(decoded.txChangesBefore)
        XCTAssertNotNil(decoded.txChangesAfter)
        XCTAssertNil(decoded.sorobanMeta)
    }

    // MARK: - TransactionMetaV4XDR Tests

    func testTransactionMetaV4XDREncodingDecoding() throws {
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])

        let metaV4 = TransactionMetaV4XDR(
            ext: .void,
            txChangesBefore: changes,
            operations: [],
            txChangesAfter: changes,
            sorobanMeta: nil,
            events: [],
            diagnosticEvents: []
        )

        let encoded = try XDREncoder.encode(metaV4)
        let decoded = try XDRDecoder.decode(TransactionMetaV4XDR.self, data: encoded)

        XCTAssertNotNil(decoded.txChangesBefore)
        XCTAssertNotNil(decoded.txChangesAfter)
        XCTAssertEqual(decoded.events.count, 0)
        XCTAssertEqual(decoded.diagnosticEvents.count, 0)
        XCTAssertNil(decoded.sorobanMeta)
    }

    func testTransactionMetaV4XDRWithSorobanMetaV2() throws {
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])
        let scVal = SCValXDR.u32(789)
        let sorobanMetaV2 = SorobanTransactionMetaV2XDR(
            ext: .void,
            returnValue: scVal
        )

        let metaV4 = TransactionMetaV4XDR(
            ext: .void,
            txChangesBefore: changes,
            operations: [],
            txChangesAfter: changes,
            sorobanMeta: sorobanMetaV2,
            events: [],
            diagnosticEvents: []
        )

        let encoded = try XDREncoder.encode(metaV4)
        let decoded = try XDRDecoder.decode(TransactionMetaV4XDR.self, data: encoded)

        XCTAssertNotNil(decoded.sorobanMeta)
        XCTAssertNotNil(decoded.sorobanMeta?.returnValue)
    }

    func testTransactionMetaV4XDRWithEvents() throws {
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])

        let scVal = SCValXDR.u32(321)
        let eventBody = ContractEventBodyXDR.v0(ContractEventBodyV0XDR(topics: [], data: scVal))
        let contractEvent = ContractEventXDR(ext: .void, hash: nil, type: ContractEventType.system.rawValue, body: eventBody)
        let txEvent = TransactionEventXDR(stage: .afterTx, event: contractEvent)

        let metaV4 = TransactionMetaV4XDR(
            ext: .void,
            txChangesBefore: changes,
            operations: [],
            txChangesAfter: changes,
            sorobanMeta: nil,
            events: [txEvent],
            diagnosticEvents: []
        )

        let encoded = try XDREncoder.encode(metaV4)
        let decoded = try XDRDecoder.decode(TransactionMetaV4XDR.self, data: encoded)

        XCTAssertEqual(decoded.events.count, 1)
        XCTAssertEqual(decoded.events[0].stage, .afterTx)
    }

    func testTransactionMetaV4XDRRoundTripBase64() throws {
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])

        let metaV4 = TransactionMetaV4XDR(
            ext: .void,
            txChangesBefore: changes,
            operations: [],
            txChangesAfter: changes,
            sorobanMeta: nil,
            events: [],
            diagnosticEvents: []
        )

        guard let base64 = metaV4.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try TransactionMetaV4XDR(xdr: base64)

        XCTAssertNotNil(decoded.txChangesBefore)
        XCTAssertNotNil(decoded.txChangesAfter)
        XCTAssertEqual(decoded.events.count, 0)
        XCTAssertNil(decoded.sorobanMeta)
    }

    // MARK: - SorobanTransactionMetaExtV1 Tests

    func testSorobanTransactionMetaExtV1EncodingDecoding() throws {
        let extV1 = SorobanTransactionMetaExtV1(
            ext: .void,
            totalNonRefundableResourceFeeCharged: 1000,
            totalRefundableResourceFeeCharged: 500,
            rentFeeCharged: 200
        )

        let encoded = try XDREncoder.encode(extV1)
        let decoded = try XDRDecoder.decode(SorobanTransactionMetaExtV1.self, data: encoded)

        XCTAssertEqual(decoded.totalNonRefundableResourceFeeCharged, 1000)
        XCTAssertEqual(decoded.totalRefundableResourceFeeCharged, 500)
        XCTAssertEqual(decoded.rentFeeCharged, 200)
    }

    func testSorobanTransactionMetaExtV1RoundTripBase64() throws {
        let extV1 = SorobanTransactionMetaExtV1(
            ext: .void,
            totalNonRefundableResourceFeeCharged: 2000,
            totalRefundableResourceFeeCharged: 1000,
            rentFeeCharged: 300
        )

        guard let base64 = extV1.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try SorobanTransactionMetaExtV1(xdr: base64)

        XCTAssertEqual(decoded.totalNonRefundableResourceFeeCharged, 2000)
        XCTAssertEqual(decoded.totalRefundableResourceFeeCharged, 1000)
        XCTAssertEqual(decoded.rentFeeCharged, 300)
    }

    // MARK: - Enum Code Tests

    func testEndSponsoringFutureReservesResultCodeRawValues() {
        XCTAssertEqual(EndSponsoringFutureReservesResultCode.success.rawValue, 0)
        XCTAssertEqual(EndSponsoringFutureReservesResultCode.notSponsored.rawValue, -1)
    }

    func testExtendFootprintTTLResultCodeRawValues() {
        XCTAssertEqual(ExtendFootprintTTLResultCode.success.rawValue, 0)
        XCTAssertEqual(ExtendFootprintTTLResultCode.malformed.rawValue, -1)
        XCTAssertEqual(ExtendFootprintTTLResultCode.resourceLimitExceeded.rawValue, -2)
        XCTAssertEqual(ExtendFootprintTTLResultCode.insufficientRefundableFee.rawValue, -3)
    }

    func testInflationResultCodeRawValues() {
        XCTAssertEqual(InflationResultCode.success.rawValue, 0)
        XCTAssertEqual(InflationResultCode.notTime.rawValue, -1)
    }

    func testInvokeHostFunctionResultCodeRawValues() {
        XCTAssertEqual(InvokeHostFunctionResultCode.success.rawValue, 0)
        XCTAssertEqual(InvokeHostFunctionResultCode.malformed.rawValue, -1)
        XCTAssertEqual(InvokeHostFunctionResultCode.trapped.rawValue, -2)
        XCTAssertEqual(InvokeHostFunctionResultCode.resourceLimitExceeded.rawValue, -3)
        XCTAssertEqual(InvokeHostFunctionResultCode.entryArchived.rawValue, -4)
        XCTAssertEqual(InvokeHostFunctionResultCode.insufficientRefundableFee.rawValue, -5)
    }

    func testLiquidityPoolDepositResulCodeRawValues() {
        XCTAssertEqual(LiquidityPoolDepositResulCode.success.rawValue, 0)
        XCTAssertEqual(LiquidityPoolDepositResulCode.malformed.rawValue, -1)
        XCTAssertEqual(LiquidityPoolDepositResulCode.noTrust.rawValue, -2)
        XCTAssertEqual(LiquidityPoolDepositResulCode.notAuthorized.rawValue, -3)
        XCTAssertEqual(LiquidityPoolDepositResulCode.underfunded.rawValue, -4)
        XCTAssertEqual(LiquidityPoolDepositResulCode.lineFull.rawValue, -5)
        XCTAssertEqual(LiquidityPoolDepositResulCode.badPrice.rawValue, -6)
        XCTAssertEqual(LiquidityPoolDepositResulCode.poolFull.rawValue, -7)
        XCTAssertEqual(LiquidityPoolDepositResulCode.trustlineFrozen.rawValue, -8)
    }

    func testLiquidityPoolWithdrawResulCodeRawValues() {
        XCTAssertEqual(LiquidityPoolWithdrawResulCode.success.rawValue, 0)
        XCTAssertEqual(LiquidityPoolWithdrawResulCode.malformed.rawValue, -1)
        XCTAssertEqual(LiquidityPoolWithdrawResulCode.noTrust.rawValue, -2)
        XCTAssertEqual(LiquidityPoolWithdrawResulCode.underfunded.rawValue, -3)
        XCTAssertEqual(LiquidityPoolWithdrawResulCode.lineFull.rawValue, -4)
        XCTAssertEqual(LiquidityPoolWithdrawResulCode.underMinimum.rawValue, -5)
        XCTAssertEqual(LiquidityPoolWithdrawResulCode.trustlineFrozen.rawValue, -6)
    }

    func testManageDataResultCodeRawValues() {
        XCTAssertEqual(ManageDataResultCode.success.rawValue, 0)
        XCTAssertEqual(ManageDataResultCode.notSupportedYet.rawValue, -1)
        XCTAssertEqual(ManageDataResultCode.nameNotFound.rawValue, -2)
        XCTAssertEqual(ManageDataResultCode.lowReserve.rawValue, -3)
        XCTAssertEqual(ManageDataResultCode.invalidName.rawValue, -4)
    }

    func testPaymentResultCodeRawValues() {
        XCTAssertEqual(PaymentResultCode.success.rawValue, 0)
        XCTAssertEqual(PaymentResultCode.malformed.rawValue, -1)
        XCTAssertEqual(PaymentResultCode.underfunded.rawValue, -2)
        XCTAssertEqual(PaymentResultCode.srcNoTrust.rawValue, -3)
        XCTAssertEqual(PaymentResultCode.srcNotAuthorized.rawValue, -4)
        XCTAssertEqual(PaymentResultCode.noDestination.rawValue, -5)
        XCTAssertEqual(PaymentResultCode.noTrust.rawValue, -6)
        XCTAssertEqual(PaymentResultCode.notAuthorized.rawValue, -7)
        XCTAssertEqual(PaymentResultCode.lineFull.rawValue, -8)
        XCTAssertEqual(PaymentResultCode.noIssuer.rawValue, -9)
    }

    func testRestoreFootprintResultCodeRawValues() {
        XCTAssertEqual(RestoreFootprintResultCode.success.rawValue, 0)
        XCTAssertEqual(RestoreFootprintResultCode.malformed.rawValue, -1)
        XCTAssertEqual(RestoreFootprintResultCode.resourceLimitExceeded.rawValue, -2)
    }

    func testRevokeSponsorshipResultCodeRawValues() {
        XCTAssertEqual(RevokeSponsorshipResultCode.success.rawValue, 0)
        XCTAssertEqual(RevokeSponsorshipResultCode.doesNotExist.rawValue, -1)
        XCTAssertEqual(RevokeSponsorshipResultCode.notSponsor.rawValue, -2)
        XCTAssertEqual(RevokeSponsorshipResultCode.lowReserve.rawValue, -3)
        XCTAssertEqual(RevokeSponsorshipResultCode.onlyTransferable.rawValue, -4)
        XCTAssertEqual(RevokeSponsorshipResultCode.malformed.rawValue, -5)
    }

    func testSetTrustLineFlagsResultCodeRawValues() {
        XCTAssertEqual(SetTrustLineFlagsResultCode.success.rawValue, 0)
        XCTAssertEqual(SetTrustLineFlagsResultCode.malformed.rawValue, -1)
        XCTAssertEqual(SetTrustLineFlagsResultCode.noTrustLine.rawValue, -2)
        XCTAssertEqual(SetTrustLineFlagsResultCode.cantRevoke.rawValue, -3)
        XCTAssertEqual(SetTrustLineFlagsResultCode.invalidState.rawValue, -4)
        XCTAssertEqual(SetTrustLineFlagsResultCode.lowReserve.rawValue, -5)
    }

    func testTransactionEventStageRawValues() {
        XCTAssertEqual(TransactionEventStage.beforeAllTxs.rawValue, 0)
        XCTAssertEqual(TransactionEventStage.afterTx.rawValue, 1)
        XCTAssertEqual(TransactionEventStage.afterAllTx.rawValue, 2)
    }

    // MARK: - Additional Error Case Tests

    func testInflationResultXDRAllErrorCases() throws {
        // Test not time error case
        let notTimeResult = InflationResultXDR.notTime

        let encoded = try XDREncoder.encode(notTimeResult)
        let decoded = try XDRDecoder.decode(InflationResultXDR.self, data: encoded)

        switch decoded {
        case .payouts:
            XCTFail("Expected notTime case")
        case .notTime:
            break
        }

        // Verify round-trip via base64
        guard let base64 = notTimeResult.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decodedFromBase64 = try InflationResultXDR(xdr: base64)
        switch decodedFromBase64 {
        case .payouts:
            XCTFail("Expected notTime case")
        case .notTime:
            break
        }
    }

    func testManageDataResultXDRAllErrorCases() throws {
        // Test all error codes for ManageData operation
        let errorCases: [ManageDataResultXDR] = [
            .notSupportedYet,
            .nameNotFound,
            .lowReserve,
            .invalidName
        ]

        for errorCase in errorCases {
            let encoded = try XDREncoder.encode(errorCase)
            let decoded = try XDRDecoder.decode(ManageDataResultXDR.self, data: encoded)

            switch decoded {
            case .success:
                XCTFail("Expected error case for \(errorCase)")
            default:
                // Verify the decoded case matches the original by re-encoding and comparing
                let reEncoded = try XDREncoder.encode(decoded)
                XCTAssertEqual(encoded, reEncoded)
            }
        }
    }

    func testBumpSequenceResultXDRAllErrorCases() throws {
        // Test bad sequence error case
        let badSeqResult = BumpSequenceResultXDR.badSeq

        let encoded = try XDREncoder.encode(badSeqResult)
        let decoded = try XDRDecoder.decode(BumpSequenceResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            XCTFail("Expected badSeq case")
        case .badSeq:
            break
        }

        // Test success case for completeness
        let successResult = BumpSequenceResultXDR.success

        let encodedSuccess = try XDREncoder.encode(successResult)
        let decodedSuccess = try XDRDecoder.decode(BumpSequenceResultXDR.self, data: encodedSuccess)

        switch decodedSuccess {
        case .success:
            break
        case .badSeq:
            XCTFail("Expected success case")
        }
    }

    func testCreateClaimableBalanceResultXDRAllErrorCases() throws {
        // Test all error codes for CreateClaimableBalance operation
        let errorCases: [CreateClaimableBalanceResultXDR] = [
            .malformed,
            .lowReserve,
            .noTrust,
            .notAuthorized,
            .underfunded
        ]

        for errorCase in errorCases {
            let encoded = try XDREncoder.encode(errorCase)
            let decoded = try XDRDecoder.decode(CreateClaimableBalanceResultXDR.self, data: encoded)

            switch decoded {
            case .balanceID:
                XCTFail("Expected error case for \(errorCase)")
            default:
                let reEncoded = try XDREncoder.encode(decoded)
                XCTAssertEqual(encoded, reEncoded)
            }
        }

        // Test success case with ClaimableBalanceID
        let balanceIdData = Data(repeating: 0xAB, count: 32)
        let balanceId = WrappedData32(balanceIdData)
        let claimableBalanceId = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(balanceId)
        let successResult = CreateClaimableBalanceResultXDR.balanceID(claimableBalanceId)

        let encodedSuccess = try XDREncoder.encode(successResult)
        let decodedSuccess = try XDRDecoder.decode(CreateClaimableBalanceResultXDR.self, data: encodedSuccess)

        switch decodedSuccess {
        case .balanceID(let decodedBalanceId):
            switch decodedBalanceId {
            case .claimableBalanceIDTypeV0(let data):
                XCTAssertEqual(data.wrapped, balanceIdData)
            }
        default:
            XCTFail("Expected balanceID case")
        }
    }

    func testLiquidityPoolDepositResultXDRAllErrorCases() throws {
        // Test all error codes for LiquidityPoolDeposit operation
        let errorCases: [LiquidityPoolDepositResultXDR] = [
            .malformed,
            .noTrust,
            .notAuthorized,
            .underfunded,
            .lineFull,
            .badPrice,
            .poolFull,
            .trustlineFrozen
        ]

        for errorCase in errorCases {
            let encoded = try XDREncoder.encode(errorCase)
            let decoded = try XDRDecoder.decode(LiquidityPoolDepositResultXDR.self, data: encoded)

            switch decoded {
            case .success:
                XCTFail("Expected error case for \(errorCase)")
            default:
                let reEncoded = try XDREncoder.encode(decoded)
                XCTAssertEqual(encoded, reEncoded)
            }
        }
    }

    func testLiquidityPoolWithdrawResultXDRAllErrorCases() throws {
        // Test all error codes for LiquidityPoolWithdraw operation
        let errorCases: [LiquidityPoolWithdrawResultXDR] = [
            .malformed,
            .noTrust,
            .underfunded,
            .lineFull,
            .underMinimum,
            .trustlineFrozen
        ]

        for errorCase in errorCases {
            let encoded = try XDREncoder.encode(errorCase)
            let decoded = try XDRDecoder.decode(LiquidityPoolWithdrawResultXDR.self, data: encoded)

            switch decoded {
            case .success:
                XCTFail("Expected error case for \(errorCase)")
            default:
                let reEncoded = try XDREncoder.encode(decoded)
                XCTAssertEqual(encoded, reEncoded)
            }
        }
    }

    // MARK: - Boundary Value Tests

    func testInt64BoundaryValuesInXDR() throws {
        // Test Int64.min, Int64.max, and 0 in XDR encoding/decoding
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        // Test with Int64.min
        let payoutMin = InflationPayoutXDR(destination: publicKey, amount: Int64.min)
        let encodedMin = try XDREncoder.encode(payoutMin)
        let decodedMin = try XDRDecoder.decode(InflationPayoutXDR.self, data: encodedMin)
        XCTAssertEqual(decodedMin.amount, Int64.min)

        // Test with Int64.max
        let payoutMax = InflationPayoutXDR(destination: publicKey, amount: Int64.max)
        let encodedMax = try XDREncoder.encode(payoutMax)
        let decodedMax = try XDRDecoder.decode(InflationPayoutXDR.self, data: encodedMax)
        XCTAssertEqual(decodedMax.amount, Int64.max)

        // Test with 0
        let payoutZero = InflationPayoutXDR(destination: publicKey, amount: 0)
        let encodedZero = try XDREncoder.encode(payoutZero)
        let decodedZero = try XDRDecoder.decode(InflationPayoutXDR.self, data: encodedZero)
        XCTAssertEqual(decodedZero.amount, 0)

        // Test boundary values in sequence numbers
        let opIdMin = OperationID(sourceAccount: publicKey, seqNum: Int64.min, opNum: 1)
        let resultMin = HashIDPreimageXDR.operationId(opIdMin)
        let encodedResultMin = try XDREncoder.encode(resultMin)
        let decodedResultMin = try XDRDecoder.decode(HashIDPreimageXDR.self, data: encodedResultMin)
        if case .operationId(let decodedOpId) = decodedResultMin {
            XCTAssertEqual(decodedOpId.seqNum, Int64.min)
        } else {
            XCTFail("Expected operationId case")
        }

        let opIdMax = OperationID(sourceAccount: publicKey, seqNum: Int64.max, opNum: 1)
        let resultMax = HashIDPreimageXDR.operationId(opIdMax)
        let encodedResultMax = try XDREncoder.encode(resultMax)
        let decodedResultMax = try XDRDecoder.decode(HashIDPreimageXDR.self, data: encodedResultMax)
        if case .operationId(let decodedOpId) = decodedResultMax {
            XCTAssertEqual(decodedOpId.seqNum, Int64.max)
        } else {
            XCTFail("Expected operationId case")
        }
    }

    func testUInt64BoundaryValuesInXDR() throws {
        // Test UInt64 boundary values (0 and UInt64.max) using SorobanTransactionMetaExtV1 fees
        // Note: SorobanTransactionMetaExtV1 uses Int64, so we test maximum positive values

        // Test with 0
        let extV1Zero = SorobanTransactionMetaExtV1(
            ext: .void,
            totalNonRefundableResourceFeeCharged: 0,
            totalRefundableResourceFeeCharged: 0,
            rentFeeCharged: 0
        )
        let encodedZero = try XDREncoder.encode(extV1Zero)
        let decodedZero = try XDRDecoder.decode(SorobanTransactionMetaExtV1.self, data: encodedZero)
        XCTAssertEqual(decodedZero.totalNonRefundableResourceFeeCharged, 0)
        XCTAssertEqual(decodedZero.totalRefundableResourceFeeCharged, 0)
        XCTAssertEqual(decodedZero.rentFeeCharged, 0)

        // Test with max positive Int64 (representing max UInt64 that fits in signed)
        let extV1Max = SorobanTransactionMetaExtV1(
            ext: .void,
            totalNonRefundableResourceFeeCharged: Int64.max,
            totalRefundableResourceFeeCharged: Int64.max,
            rentFeeCharged: Int64.max
        )
        let encodedMax = try XDREncoder.encode(extV1Max)
        let decodedMax = try XDRDecoder.decode(SorobanTransactionMetaExtV1.self, data: encodedMax)
        XCTAssertEqual(decodedMax.totalNonRefundableResourceFeeCharged, Int64.max)
        XCTAssertEqual(decodedMax.totalRefundableResourceFeeCharged, Int64.max)
        XCTAssertEqual(decodedMax.rentFeeCharged, Int64.max)

        // Test SCValXDR with u64 type for true UInt64 boundary testing
        let scValZero = SCValXDR.u64(0)
        let encodedScValZero = try XDREncoder.encode(scValZero)
        let decodedScValZero = try XDRDecoder.decode(SCValXDR.self, data: encodedScValZero)
        if case .u64(let value) = decodedScValZero {
            XCTAssertEqual(value, 0)
        } else {
            XCTFail("Expected u64 case")
        }

        let scValMax = SCValXDR.u64(UInt64.max)
        let encodedScValMax = try XDREncoder.encode(scValMax)
        let decodedScValMax = try XDRDecoder.decode(SCValXDR.self, data: encodedScValMax)
        if case .u64(let value) = decodedScValMax {
            XCTAssertEqual(value, UInt64.max)
        } else {
            XCTFail("Expected u64 case")
        }
    }

    func testInt32BoundaryValuesInXDR() throws {
        // Test Int32 boundary values using SCValXDR i32 type

        // Test SCValXDR with i32 type - Int32.min
        let scValMin = SCValXDR.i32(Int32.min)
        let encodedScValMin = try XDREncoder.encode(scValMin)
        let decodedScValMin = try XDRDecoder.decode(SCValXDR.self, data: encodedScValMin)
        if case .i32(let value) = decodedScValMin {
            XCTAssertEqual(value, Int32.min)
        } else {
            XCTFail("Expected i32 case")
        }

        // Test SCValXDR with i32 type - Int32.max
        let scValMax = SCValXDR.i32(Int32.max)
        let encodedScValMax = try XDREncoder.encode(scValMax)
        let decodedScValMax = try XDRDecoder.decode(SCValXDR.self, data: encodedScValMax)
        if case .i32(let value) = decodedScValMax {
            XCTAssertEqual(value, Int32.max)
        } else {
            XCTFail("Expected i32 case")
        }

        // Test SCValXDR with i32 type - 0
        let scValZero = SCValXDR.i32(0)
        let encodedScValZero = try XDREncoder.encode(scValZero)
        let decodedScValZero = try XDRDecoder.decode(SCValXDR.self, data: encodedScValZero)
        if case .i32(let value) = decodedScValZero {
            XCTAssertEqual(value, 0)
        } else {
            XCTFail("Expected i32 case")
        }

        // Test that PaymentResultXDR noIssuer encodes/decodes correctly
        let resultNoIssuer = PaymentResultXDR.noIssuer
        let encodedResultMin = try XDREncoder.encode(resultNoIssuer)
        let decodedResultMin = try XDRDecoder.decode(PaymentResultXDR.self, data: encodedResultMin)
        switch decodedResultMin {
        case .noIssuer:
            break
        default:
            XCTFail("Expected noIssuer case")
        }

        // Test success result code
        let resultSuccess = PaymentResultXDR.success
        let encodedResultZero = try XDREncoder.encode(resultSuccess)
        let decodedResultZero = try XDRDecoder.decode(PaymentResultXDR.self, data: encodedResultZero)
        switch decodedResultZero {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testUInt32BoundaryValuesInXDR() throws {
        // Test UInt32 boundary values (0 and UInt32.max) using SCValXDR

        // Test SCValXDR with u32 type - 0
        let scValZero = SCValXDR.u32(0)
        let encodedScValZero = try XDREncoder.encode(scValZero)
        let decodedScValZero = try XDRDecoder.decode(SCValXDR.self, data: encodedScValZero)
        if case .u32(let value) = decodedScValZero {
            XCTAssertEqual(value, 0)
        } else {
            XCTFail("Expected u32 case")
        }

        // Test SCValXDR with u32 type - UInt32.max
        let scValMax = SCValXDR.u32(UInt32.max)
        let encodedScValMax = try XDREncoder.encode(scValMax)
        let decodedScValMax = try XDRDecoder.decode(SCValXDR.self, data: encodedScValMax)
        if case .u32(let value) = decodedScValMax {
            XCTAssertEqual(value, UInt32.max)
        } else {
            XCTFail("Expected u32 case")
        }

        // Test round-trip via base64 encoding
        guard let base64Zero = scValZero.xdrEncoded else {
            XCTFail("Failed to encode u32(0) to base64")
            return
        }
        let decodedFromBase64Zero = try SCValXDR(xdr: base64Zero)
        if case .u32(let value) = decodedFromBase64Zero {
            XCTAssertEqual(value, 0)
        } else {
            XCTFail("Expected u32 case")
        }

        guard let base64Max = scValMax.xdrEncoded else {
            XCTFail("Failed to encode u32(max) to base64")
            return
        }
        let decodedFromBase64Max = try SCValXDR(xdr: base64Max)
        if case .u32(let value) = decodedFromBase64Max {
            XCTAssertEqual(value, UInt32.max)
        } else {
            XCTFail("Expected u32 case")
        }

        // Verify specific boundary value
        XCTAssertEqual(UInt32.max, 4294967295)
    }
}
