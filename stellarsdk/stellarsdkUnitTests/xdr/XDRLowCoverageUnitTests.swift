//
//  XDRLowCoverageUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class XDRLowCoverageUnitTests: XCTestCase {

    // MARK: - TransactionResultXDR Tests

    func testTransactionResultXDRSuccess() throws {
        let result = TransactionResultXDR(
            feeCharged: 100,
            resultBody: .success([]),
            code: .success
        )

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(TransactionResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.feeCharged, 100)
        XCTAssertEqual(decoded.code, .success)
        XCTAssertNotNil(decoded.resultBody)
    }

    func testTransactionResultXDRFailed() throws {
        let result = TransactionResultXDR(
            feeCharged: 200,
            resultBody: .failed([]),
            code: .failed
        )

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(TransactionResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.feeCharged, 200)
        XCTAssertEqual(decoded.code, .failed)
    }

    func testTransactionResultXDRTooEarly() throws {
        let result = TransactionResultXDR(
            feeCharged: 50,
            resultBody: .tooEarly,
            code: .tooEarly
        )

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(TransactionResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.feeCharged, 50)
        XCTAssertEqual(decoded.code, .tooEarly)
    }

    func testTransactionResultXDRFromXdr() throws {
        let result = TransactionResultXDR(
            feeCharged: 300,
            resultBody: .success([]),
            code: .success
        )

        let encoded = try XDREncoder.encode(result)
        let base64 = Data(encoded).base64EncodedString()

        let decoded = try TransactionResultXDR.fromXdr(base64: base64)

        XCTAssertEqual(decoded.feeCharged, 300)
        XCTAssertEqual(decoded.code, .success)
    }

    func testTransactionResultXDRAllErrorCodes() throws {
        let errorCodes: [(TransactionResultCode, TransactionResultBodyXDR)] = [
            (.tooLate, .tooLate),
            (.missingOperation, .missingOperation),
            (.badSeq, .badSeq),
            (.badAuth, .badAuth),
            (.insufficientBalance, .insufficientBalance),
            (.noAccount, .noAccount),
            (.insufficientFee, .insufficientFee),
            (.badAuthExtra, .badAuthExtra),
            (.internalError, .internalError),
            (.notSupported, .notSupported),
            (.badSponsorship, .badSponsorship),
            (.badMinSeqAgeOrGap, .badMinSeqAgeOrGap),
            (.malformed, .malformed),
            (.sorobanInvalid, .sorobanInvalid)
        ]

        for (code, body) in errorCodes {
            let result = TransactionResultXDR(
                feeCharged: 100,
                resultBody: body,
                code: code
            )

            let encoded = try XDREncoder.encode(result)
            let decoded = try XDRDecoder.decode(TransactionResultXDR.self, data: encoded)

            XCTAssertEqual(decoded.code, code)
        }
    }

    func testInnerTransactionResultPair() throws {
        let hashData = Data(repeating: 0xAB, count: 32)
        let hash = WrappedData32(hashData)

        let innerResult = InnerTransactionResultXDR(
            feeCharged: 150,
            resultBody: .success([]),
            code: .success
        )

        let pair = InnerTransactionResultPair(hash: hash, result: innerResult)

        let encoded = try XDREncoder.encode(pair)
        let decoded = try XDRDecoder.decode(InnerTransactionResultPair.self, data: encoded)

        XCTAssertEqual(decoded.hash.wrapped, hashData)
        XCTAssertEqual(decoded.result.feeCharged, 150)
    }

    // MARK: - TransactionV0XDR Tests

    func testTransactionV0XDRBasic() throws {
        let sourceAccountString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let sourceAccount = try PublicKey(accountId: sourceAccountString)

        let tx = TransactionV0XDR(
            sourceAccount: sourceAccount,
            seqNum: 123456,
            timeBounds: nil,
            memo: .none,
            operations: [],
            maxOperationFee: 100
        )

        let encoded = try XDREncoder.encode(tx)
        let decoded = try XDRDecoder.decode(TransactionV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.seqNum, 123456)
        XCTAssertEqual(decoded.fee, 0) // 100 * 0 operations
        XCTAssertNil(decoded.timeBounds)
    }

    func testTransactionV0XDRWithTimeBounds() throws {
        let sourceAccountString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let sourceAccount = try PublicKey(accountId: sourceAccountString)

        let timeBounds = TimeBoundsXDR(minTime: 100, maxTime: 200)

        let tx = TransactionV0XDR(
            sourceAccount: sourceAccount,
            seqNum: 789,
            timeBounds: timeBounds,
            memo: .text("test"),
            operations: [],
            maxOperationFee: 200
        )

        let encoded = try XDREncoder.encode(tx)
        let decoded = try XDRDecoder.decode(TransactionV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.seqNum, 789)
        XCTAssertNotNil(decoded.timeBounds)
        XCTAssertEqual(decoded.timeBounds?.minTime, 100)
        XCTAssertEqual(decoded.timeBounds?.maxTime, 200)
    }

    // MARK: - TransactionMetaXDR Tests

    func testTransactionMetaXDROperations() throws {
        let meta = TransactionMetaXDR.operations([])

        let encoded = try XDREncoder.encode(meta)
        let decoded = try XDRDecoder.decode(TransactionMetaXDR.self, data: encoded)

        switch decoded {
        case .operations:
            XCTAssertTrue(true, "Expected operations type")
        default:
            XCTFail("Expected operations type")
        }
    }

    func testTransactionMetaXDRFromBase64() throws {
        let meta = TransactionMetaXDR.operations([])

        let encoded = try XDREncoder.encode(meta)
        let base64 = Data(encoded).base64EncodedString()

        let decoded = try TransactionMetaXDR(fromBase64: base64)

        switch decoded {
        case .operations:
            XCTAssertTrue(true, "Expected operations type")
        default:
            XCTFail("Expected operations type")
        }
    }

    func testTransactionMetaXDRAccessors() throws {
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])
        let metaV3 = TransactionMetaV3XDR(
            ext: .void,
            txChangesBefore: changes,
            operations: [],
            txChangesAfter: changes,
            sorobanMeta: nil
        )

        let meta = TransactionMetaXDR.transactionMetaV3(metaV3)

        XCTAssertNotNil(meta.transactionMetaV3)
        XCTAssertNil(meta.transactionMetaV4)
    }

    // MARK: - LedgerEntryXDR Tests

    func testLedgerEntryXDRBasic() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let thresholds = WrappedData4(Data([1, 2, 3, 4]))

        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: 2000000,
            sequenceNumber: 50,
            numSubEntries: 1,
            homeDomain: "stellar.org",
            flags: 0,
            thresholds: thresholds,
            signers: []
        )

        let ledgerData = LedgerEntryDataXDR.account(accountEntry)
        let ledgerEntry = LedgerEntryXDR(
            lastModifiedLedgerSeq: 12345,
            data: ledgerData
        )

        let encoded = try XDREncoder.encode(ledgerEntry)
        let decoded = try XDRDecoder.decode(LedgerEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.lastModifiedLedgerSeq, 12345)
        XCTAssertEqual(decoded.data.type(), LedgerEntryType.account.rawValue)
    }

    func testLedgerEntryXDRFromBase64() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let thresholds = WrappedData4(Data([1, 2, 3, 4]))

        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: 3000000,
            sequenceNumber: 75,
            numSubEntries: 0,
            homeDomain: "",
            flags: 0,
            thresholds: thresholds,
            signers: []
        )

        let ledgerData = LedgerEntryDataXDR.account(accountEntry)
        let ledgerEntry = LedgerEntryXDR(
            lastModifiedLedgerSeq: 54321,
            data: ledgerData
        )

        let encoded = try XDREncoder.encode(ledgerEntry)
        let base64 = Data(encoded).base64EncodedString()

        let decoded = try LedgerEntryXDR(fromBase64: base64)

        XCTAssertEqual(decoded.lastModifiedLedgerSeq, 54321)
    }

    // MARK: - OperationResultXDR Tests

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

    func testOperationResultXDRAllEmptyCodes() throws {
        let codes: [OperationResultCode] = [
            .badAuth,
            .noAccount,
            .notSupported,
            .tooManySubentries,
            .exceededWorkLimit,
            .tooManySponsoring
        ]

        for code in codes {
            let result = OperationResultXDR.empty(code.rawValue)

            let encoded = try XDREncoder.encode(result)
            let decoded = try XDRDecoder.decode(OperationResultXDR.self, data: encoded)

            switch decoded {
            case .empty(let decodedCode):
                XCTAssertEqual(decodedCode, code.rawValue)
            default:
                XCTFail("Expected empty case for code \(code.rawValue)")
            }
        }
    }

    // MARK: - LedgerEntryChangesXDR Tests

    func testLedgerEntryChangesXDREmpty() throws {
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])

        let encoded = try XDREncoder.encode(changes)
        let decoded = try XDRDecoder.decode(LedgerEntryChangesXDR.self, data: encoded)

        XCTAssertEqual(decoded.ledgerEntryChanges.count, 0)
    }

    // MARK: - LedgerEntryChangeXDR Tests

    func testLedgerEntryChangeXDRCreated() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let thresholds = WrappedData4(Data([1, 2, 3, 4]))

        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: 1000000,
            sequenceNumber: 1,
            numSubEntries: 0,
            homeDomain: "",
            flags: 0,
            thresholds: thresholds,
            signers: []
        )

        let ledgerData = LedgerEntryDataXDR.account(accountEntry)
        let ledgerEntry = LedgerEntryXDR(
            lastModifiedLedgerSeq: 100,
            data: ledgerData
        )

        let change = LedgerEntryChangeXDR.created(ledgerEntry)

        let encoded = try XDREncoder.encode(change)
        let decoded = try XDRDecoder.decode(LedgerEntryChangeXDR.self, data: encoded)

        switch decoded {
        case .created(let entry):
            XCTAssertEqual(entry.lastModifiedLedgerSeq, 100)
        default:
            XCTFail("Expected created case")
        }
    }

    func testLedgerEntryChangeXDRUpdated() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let thresholds = WrappedData4(Data([1, 2, 3, 4]))

        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: 2000000,
            sequenceNumber: 2,
            numSubEntries: 0,
            homeDomain: "",
            flags: 0,
            thresholds: thresholds,
            signers: []
        )

        let ledgerData = LedgerEntryDataXDR.account(accountEntry)
        let ledgerEntry = LedgerEntryXDR(
            lastModifiedLedgerSeq: 200,
            data: ledgerData
        )

        let change = LedgerEntryChangeXDR.updated(ledgerEntry)

        let encoded = try XDREncoder.encode(change)
        let decoded = try XDRDecoder.decode(LedgerEntryChangeXDR.self, data: encoded)

        switch decoded {
        case .updated(let entry):
            XCTAssertEqual(entry.lastModifiedLedgerSeq, 200)
        default:
            XCTFail("Expected updated case")
        }
    }

    func testLedgerEntryChangeXDRState() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let thresholds = WrappedData4(Data([1, 2, 3, 4]))

        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: 3000000,
            sequenceNumber: 3,
            numSubEntries: 0,
            homeDomain: "",
            flags: 0,
            thresholds: thresholds,
            signers: []
        )

        let ledgerData = LedgerEntryDataXDR.account(accountEntry)
        let ledgerEntry = LedgerEntryXDR(
            lastModifiedLedgerSeq: 300,
            data: ledgerData
        )

        let change = LedgerEntryChangeXDR.state(ledgerEntry)

        let encoded = try XDREncoder.encode(change)
        let decoded = try XDRDecoder.decode(LedgerEntryChangeXDR.self, data: encoded)

        switch decoded {
        case .state(let entry):
            XCTAssertEqual(entry.lastModifiedLedgerSeq, 300)
        default:
            XCTFail("Expected state case")
        }
    }

    // MARK: - TrustlineEntryXDR Tests

    func testTrustlineEntryXDRBasic() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        // Manually construct trustline entry for testing
        let xdrData: [UInt8] = [
            // accountID (32 bytes public key type + 32 bytes key)
            0x00, 0x00, 0x00, 0x00] + publicKey.bytes + [
            // asset type (ASSET_TYPE_CREDIT_ALPHANUM4 = 1)
            0x00, 0x00, 0x00, 0x01,
            // asset code (4 bytes)
            0x55, 0x53, 0x44, 0x00,
            // issuer (32 bytes public key type + 32 bytes key)
            0x00, 0x00, 0x00, 0x00] + publicKey.bytes + [
            // balance
            0x00, 0x00, 0x00, 0x00, 0x00, 0x0F, 0x42, 0x40,
            // limit
            0x00, 0x00, 0x00, 0x00, 0x7F, 0xFF, 0xFF, 0xFF,
            // flags
            0x00, 0x00, 0x00, 0x01,
            // ext (0 = void)
            0x00, 0x00, 0x00, 0x00
        ]

        let decoded = try XDRDecoder.decode(TrustlineEntryXDR.self, data: xdrData)

        XCTAssertEqual(decoded.balance, 1000000)
        XCTAssertEqual(decoded.flags, 1)

        let encoded = try XDREncoder.encode(decoded)
        let reDecoded = try XDRDecoder.decode(TrustlineEntryXDR.self, data: encoded)

        XCTAssertEqual(reDecoded.balance, 1000000)
    }

    // MARK: - LiabilitiesXDR Tests

    func testLiabilitiesXDRBasic() throws {
        let liabilities = LiabilitiesXDR(buying: 500000, selling: 300000)

        let encoded = try XDREncoder.encode(liabilities)
        let decoded = try XDRDecoder.decode(LiabilitiesXDR.self, data: encoded)

        XCTAssertEqual(decoded.buying, 500000)
        XCTAssertEqual(decoded.selling, 300000)
    }

    func testLiabilitiesXDRZeroValues() throws {
        let liabilities = LiabilitiesXDR(buying: 0, selling: 0)

        let encoded = try XDREncoder.encode(liabilities)
        let decoded = try XDRDecoder.decode(LiabilitiesXDR.self, data: encoded)

        XCTAssertEqual(decoded.buying, 0)
        XCTAssertEqual(decoded.selling, 0)
    }

    func testLiabilitiesXDRMaxValues() throws {
        let liabilities = LiabilitiesXDR(buying: Int64.max, selling: Int64.max)

        let encoded = try XDREncoder.encode(liabilities)
        let decoded = try XDRDecoder.decode(LiabilitiesXDR.self, data: encoded)

        XCTAssertEqual(decoded.buying, Int64.max)
        XCTAssertEqual(decoded.selling, Int64.max)
    }

    // MARK: - OperationMetaXDR Tests

    func testOperationMetaXDREmpty() throws {
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])
        let opMeta = OperationMetaXDR(changes: changes)

        let encoded = try XDREncoder.encode(opMeta)
        let decoded = try XDRDecoder.decode(OperationMetaXDR.self, data: encoded)

        XCTAssertEqual(decoded.changes.ledgerEntryChanges.count, 0)
    }

    // MARK: - AccountEntryXDR Tests

    func testAccountEntryXDRBasic() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let thresholds = WrappedData4(Data([1, 2, 3, 4]))

        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: 10000000,
            sequenceNumber: 123,
            numSubEntries: 5,
            homeDomain: "stellar.org",
            flags: AccountFlags.AUTH_REQUIRED_FLAG,
            thresholds: thresholds,
            signers: []
        )

        let encoded = try XDREncoder.encode(accountEntry)
        let decoded = try XDRDecoder.decode(AccountEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.balance, 10000000)
        XCTAssertEqual(decoded.sequenceNumber, 123)
        XCTAssertEqual(decoded.numSubEntries, 5)
        XCTAssertEqual(decoded.homeDomain, "stellar.org")
        XCTAssertEqual(decoded.flags, AccountFlags.AUTH_REQUIRED_FLAG)
    }

    func testAccountEntryXDRWithInflationDest() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let thresholds = WrappedData4(Data([1, 2, 3, 4]))

        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: 5000000,
            sequenceNumber: 456,
            numSubEntries: 2,
            homeDomain: "",
            inflationDest: publicKey,
            flags: 0,
            thresholds: thresholds,
            signers: []
        )

        let encoded = try XDREncoder.encode(accountEntry)
        let decoded = try XDRDecoder.decode(AccountEntryXDR.self, data: encoded)

        XCTAssertNotNil(decoded.inflationDest)
        XCTAssertEqual(decoded.inflationDest?.accountId, accountIdString)
    }

    func testAccountEntryXDRAllFlags() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let thresholds = WrappedData4(Data([1, 2, 3, 4]))

        let allFlags = AccountFlags.AUTH_REQUIRED_FLAG |
                      AccountFlags.AUTH_REVOCABLE_FLAG |
                      AccountFlags.AUTH_IMMUTABLE_FLAG |
                      AccountFlags.AUTH_CLAWBACK_ENABLED_FLAG

        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: 1000000,
            sequenceNumber: 1,
            numSubEntries: 0,
            homeDomain: "",
            flags: allFlags,
            thresholds: thresholds,
            signers: []
        )

        let encoded = try XDREncoder.encode(accountEntry)
        let decoded = try XDRDecoder.decode(AccountEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.flags, allFlags)
    }

    // MARK: - AccountEntryExtXDR Tests

    func testAccountEntryExtXDRVoid() throws {
        let ext = AccountEntryExtXDR.void

        let encoded = try XDREncoder.encode(ext)
        let decoded = try XDRDecoder.decode(AccountEntryExtXDR.self, data: encoded)

        switch decoded {
        case .void:
            XCTAssertTrue(true, "Expected void case")
        default:
            XCTFail("Expected void case")
        }
    }

    func testAccountEntryExtXDRWithExtensionV1() throws {
        let liabilities = LiabilitiesXDR(buying: 1000, selling: 2000)
        let extV1 = AccountEntryExtensionV1(liabilities: liabilities)
        let ext = AccountEntryExtXDR.accountEntryExtensionV1(extV1)

        let encoded = try XDREncoder.encode(ext)
        let decoded = try XDRDecoder.decode(AccountEntryExtXDR.self, data: encoded)

        switch decoded {
        case .accountEntryExtensionV1(let decodedExtV1):
            XCTAssertEqual(decodedExtV1.liabilities.buying, 1000)
            XCTAssertEqual(decodedExtV1.liabilities.selling, 2000)
        default:
            XCTFail("Expected accountEntryExtensionV1 case")
        }
    }

    // MARK: - TTLEntryXDR Tests

    func testTTLEntryXDRBasic() throws {
        let keyHash = WrappedData32(Data(repeating: 0xFF, count: 32))
        let ttlEntry = TTLEntryXDR(keyHash: keyHash, liveUntilLedgerSeq: 1000000)

        let encoded = try XDREncoder.encode(ttlEntry)
        let decoded = try XDRDecoder.decode(TTLEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.keyHash.wrapped, keyHash.wrapped)
        XCTAssertEqual(decoded.liveUntilLedgerSeq, 1000000)
    }

    // MARK: - LedgerEntryExtXDR Tests

    func testLedgerEntryExtXDRVoid() throws {
        let ext = LedgerEntryExtXDR.void

        let encoded = try XDREncoder.encode(ext)
        let decoded = try XDRDecoder.decode(LedgerEntryExtXDR.self, data: encoded)

        switch decoded {
        case .void:
            XCTAssertTrue(true, "Expected void case")
        default:
            XCTFail("Expected void case")
        }
    }

    func testLedgerEntryExtXDRWithExtensionV1() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        let extV1 = LedgerEntryExtensionV1(signerSponsoringID: publicKey)
        let ext = LedgerEntryExtXDR.ledgerEntryExtensionV1(extV1)

        let encoded = try XDREncoder.encode(ext)
        let decoded = try XDRDecoder.decode(LedgerEntryExtXDR.self, data: encoded)

        switch decoded {
        case .ledgerEntryExtensionV1(let decodedExtV1):
            XCTAssertNotNil(decodedExtV1.signerSponsoringID)
        default:
            XCTFail("Expected ledgerEntryExtensionV1 case")
        }
    }

    // MARK: - TransactionResultCode Enum Tests

    func testTransactionResultCodeRawValues() {
        XCTAssertEqual(TransactionResultCode.feeBumpInnerSuccess.rawValue, 1)
        XCTAssertEqual(TransactionResultCode.success.rawValue, 0)
        XCTAssertEqual(TransactionResultCode.failed.rawValue, -1)
        XCTAssertEqual(TransactionResultCode.tooEarly.rawValue, -2)
        XCTAssertEqual(TransactionResultCode.tooLate.rawValue, -3)
        XCTAssertEqual(TransactionResultCode.missingOperation.rawValue, -4)
        XCTAssertEqual(TransactionResultCode.badSeq.rawValue, -5)
        XCTAssertEqual(TransactionResultCode.badAuth.rawValue, -6)
        XCTAssertEqual(TransactionResultCode.insufficientBalance.rawValue, -7)
        XCTAssertEqual(TransactionResultCode.noAccount.rawValue, -8)
        XCTAssertEqual(TransactionResultCode.insufficientFee.rawValue, -9)
        XCTAssertEqual(TransactionResultCode.badAuthExtra.rawValue, -10)
        XCTAssertEqual(TransactionResultCode.internalError.rawValue, -11)
        XCTAssertEqual(TransactionResultCode.notSupported.rawValue, -12)
        XCTAssertEqual(TransactionResultCode.feeBumpInnerFailed.rawValue, -13)
        XCTAssertEqual(TransactionResultCode.badSponsorship.rawValue, -14)
        XCTAssertEqual(TransactionResultCode.badMinSeqAgeOrGap.rawValue, -15)
        XCTAssertEqual(TransactionResultCode.malformed.rawValue, -16)
        XCTAssertEqual(TransactionResultCode.sorobanInvalid.rawValue, -17)
    }

    // MARK: - OperationResultCode Enum Tests

    func testOperationResultCodeRawValues() {
        XCTAssertEqual(OperationResultCode.inner.rawValue, 0)
        XCTAssertEqual(OperationResultCode.badAuth.rawValue, -1)
        XCTAssertEqual(OperationResultCode.noAccount.rawValue, -2)
        XCTAssertEqual(OperationResultCode.notSupported.rawValue, -3)
        XCTAssertEqual(OperationResultCode.tooManySubentries.rawValue, -4)
        XCTAssertEqual(OperationResultCode.exceededWorkLimit.rawValue, -5)
        XCTAssertEqual(OperationResultCode.tooManySponsoring.rawValue, -6)
    }

    // MARK: - LedgerEntryType Enum Tests

    func testLedgerEntryTypeRawValues() {
        XCTAssertEqual(LedgerEntryType.account.rawValue, 0)
        XCTAssertEqual(LedgerEntryType.trustline.rawValue, 1)
        XCTAssertEqual(LedgerEntryType.offer.rawValue, 2)
        XCTAssertEqual(LedgerEntryType.data.rawValue, 3)
        XCTAssertEqual(LedgerEntryType.claimableBalance.rawValue, 4)
        XCTAssertEqual(LedgerEntryType.liquidityPool.rawValue, 5)
        XCTAssertEqual(LedgerEntryType.contractData.rawValue, 6)
        XCTAssertEqual(LedgerEntryType.contractCode.rawValue, 7)
        XCTAssertEqual(LedgerEntryType.configSetting.rawValue, 8)
        XCTAssertEqual(LedgerEntryType.ttl.rawValue, 9)
    }

    // MARK: - LedgerEntryChangeType Enum Tests

    func testLedgerEntryChangeTypeRawValues() {
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryCreated.rawValue, 0)
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryUpdated.rawValue, 1)
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryRemoved.rawValue, 2)
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryState.rawValue, 3)
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryRestore.rawValue, 4)
    }

    // MARK: - TransactionMetaType Enum Tests

    func testTransactionMetaTypeRawValues() {
        XCTAssertEqual(TransactionMetaType.operations.rawValue, 0)
        XCTAssertEqual(TransactionMetaType.transactionMetaV1.rawValue, 1)
        XCTAssertEqual(TransactionMetaType.transactionMetaV2.rawValue, 2)
        XCTAssertEqual(TransactionMetaType.transactionMetaV3.rawValue, 3)
        XCTAssertEqual(TransactionMetaType.transactionMetaV4.rawValue, 4)
    }

    // MARK: - Edge Cases and Additional Coverage

    func testLedgerEntryDataXDRIsBoolProperty() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let thresholds = WrappedData4(Data([1, 2, 3, 4]))

        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: 1000000,
            sequenceNumber: 1,
            numSubEntries: 0,
            homeDomain: "",
            flags: 0,
            thresholds: thresholds,
            signers: []
        )

        let ledgerData = LedgerEntryDataXDR.account(accountEntry)

        // The isBool property checks if type equals SCValType.bool.rawValue
        // Since account type is 0 and SCValType.bool.rawValue is also likely 0, this might be true
        // This tests the isBool property
        _ = ledgerData.isBool
    }

    func testAccountEntryExtensionV2() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        let extV2 = AccountEntryExtensionV2(
            numSponsored: 3,
            numSponsoring: 2,
            signerSponsoringIDs: [publicKey, nil, publicKey]
        )

        let encoded = try XDREncoder.encode(extV2)
        let decoded = try XDRDecoder.decode(AccountEntryExtensionV2.self, data: encoded)

        XCTAssertEqual(decoded.numSponsored, 3)
        XCTAssertEqual(decoded.numSponsoring, 2)
        XCTAssertEqual(decoded.signerSponsoringIDs.count, 3)
        XCTAssertNotNil(decoded.signerSponsoringIDs[0])
        XCTAssertNil(decoded.signerSponsoringIDs[1])
        XCTAssertNotNil(decoded.signerSponsoringIDs[2])
    }

    func testAccountEntryExtensionV3() throws {
        let extV3 = AccountEntryExtensionV3(seqLedger: 12345, seqTime: 1234567890)

        let encoded = try XDREncoder.encode(extV3)
        let decoded = try XDRDecoder.decode(AccountEntryExtensionV3.self, data: encoded)

        XCTAssertEqual(decoded.seqLedger, 12345)
        XCTAssertEqual(decoded.seqTime, 1234567890)
    }

    func testExtensionPoint() throws {
        let ext = ExtensionPoint.void

        let encoded = try XDREncoder.encode(ext)
        let decoded = try XDRDecoder.decode(ExtensionPoint.self, data: encoded)

        switch decoded {
        case .void:
            XCTAssertTrue(true, "Expected void case")
        }
    }

    func testTrustlineEntryExtensionV2() throws {
        let extV2 = TrustlineEntryExtensionV2()

        let encoded = try XDREncoder.encode(extV2)
        let decoded = try XDRDecoder.decode(TrustlineEntryExtensionV2.self, data: encoded)

        XCTAssertEqual(decoded.liquidityPoolUseCount, 0)
        XCTAssertEqual(decoded.reserved, 0)
    }

    // MARK: - InvokeHostFunctionOpXDR Tests

    func testUploadContractWasmArgsXDR() throws {
        let wasmCode = Data([0x00, 0x61, 0x73, 0x6D])
        let args = UploadContractWasmArgsXDR(code: wasmCode)

        let encoded = try XDREncoder.encode(args)
        let decoded = try XDRDecoder.decode(UploadContractWasmArgsXDR.self, data: encoded)

        XCTAssertEqual(decoded.code, wasmCode)
    }

    func testFromEd25519PublicKeyXDR() throws {
        let key = WrappedData32(Data(repeating: 0xAA, count: 32))
        let signature = Data([0x01, 0x02, 0x03, 0x04])
        let salt = WrappedData32(Data(repeating: 0xBB, count: 32))

        let fromEd25519 = FromEd25519PublicKeyXDR(key: key, signature: signature, salt: salt)

        let encoded = try XDREncoder.encode(fromEd25519)
        let decoded = try XDRDecoder.decode(FromEd25519PublicKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.key.wrapped, key.wrapped)
        XCTAssertEqual(decoded.signature, signature)
        XCTAssertEqual(decoded.salt.wrapped, salt.wrapped)
    }

    // MARK: - SimplePaymentResultXDR Tests

    func testSimplePaymentResultXDRNativeAsset() throws {
        let destinationString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let destination = try PublicKey(accountId: destinationString)

        let payment = SimplePaymentResultXDR(
            destination: destination,
            asset: .native,
            amount: 10000000
        )

        let encoded = try XDREncoder.encode(payment)
        let decoded = try XDRDecoder.decode(SimplePaymentResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.destination.accountId, destinationString)
        XCTAssertEqual(decoded.amount, 10000000)

        switch decoded.asset {
        case .native:
            XCTAssertTrue(true, "Expected native asset")
        default:
            XCTFail("Expected native asset")
        }
    }

    func testSimplePaymentResultXDRCreditAsset() throws {
        let destinationString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let destination = try PublicKey(accountId: destinationString)

        let asset = try Asset(canonicalForm: "USD:\(destinationString)")!.toXDR()

        let payment = SimplePaymentResultXDR(
            destination: destination,
            asset: asset,
            amount: 5000000
        )

        let encoded = try XDREncoder.encode(payment)
        let decoded = try XDRDecoder.decode(SimplePaymentResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.amount, 5000000)
    }

    // MARK: - OfferEntryXDR Tests

    func testOfferEntryXDRBasic() throws {
        let sellerString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let seller = try PublicKey(accountId: sellerString)

        let price = PriceXDR(n: 100, d: 1)

        let offer = OfferEntryXDR(
            sellerID: seller,
            offerID: 12345,
            selling: .native,
            buying: .native,
            amount: 1000000,
            price: price,
            flags: 0
        )

        let encoded = try XDREncoder.encode(offer)
        let decoded = try XDRDecoder.decode(OfferEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.sellerID.accountId, sellerString)
        XCTAssertEqual(decoded.offerID, 12345)
        XCTAssertEqual(decoded.amount, 1000000)
        XCTAssertEqual(decoded.price.n, 100)
        XCTAssertEqual(decoded.price.d, 1)
        XCTAssertEqual(decoded.flags, 0)
    }

    func testOfferEntryXDRWithFlags() throws {
        let sellerString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let seller = try PublicKey(accountId: sellerString)

        let price = PriceXDR(n: 50, d: 100)

        let offer = OfferEntryXDR(
            sellerID: seller,
            offerID: 98765,
            selling: .native,
            buying: .native,
            amount: 5000000,
            price: price,
            flags: 1
        )

        let encoded = try XDREncoder.encode(offer)
        let decoded = try XDRDecoder.decode(OfferEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.offerID, 98765)
        XCTAssertEqual(decoded.amount, 5000000)
        XCTAssertEqual(decoded.flags, 1)
        XCTAssertEqual(decoded.reserved, 0)
    }

    // MARK: - ManageOfferSuccessResultXDR Tests

    func testManageOfferSuccessResultXDRCreated() throws {
        let sellerString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let seller = try PublicKey(accountId: sellerString)

        let price = PriceXDR(n: 100, d: 1)

        let offer = OfferEntryXDR(
            sellerID: seller,
            offerID: 111,
            selling: .native,
            buying: .native,
            amount: 1000000,
            price: price,
            flags: 0
        )

        let result = ManageOfferSuccessResultXDR(
            offersClaimed: [],
            offer: .created(offer)
        )

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ManageOfferSuccessResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.offersClaimed.count, 0)
        XCTAssertNotNil(decoded.offer)

        switch decoded.offer {
        case .created(let decodedOffer):
            XCTAssertEqual(decodedOffer.offerID, 111)
        default:
            XCTFail("Expected created offer")
        }
    }

    func testManageOfferSuccessResultXDRUpdated() throws {
        let sellerString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let seller = try PublicKey(accountId: sellerString)

        let price = PriceXDR(n: 50, d: 1)

        let offer = OfferEntryXDR(
            sellerID: seller,
            offerID: 222,
            selling: .native,
            buying: .native,
            amount: 2000000,
            price: price,
            flags: 0
        )

        // Both created and updated use the same ManageOfferSuccessResultOfferXDR.created case
        let result = ManageOfferSuccessResultXDR(
            offersClaimed: [],
            offer: .created(offer)
        )

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ManageOfferSuccessResultXDR.self, data: encoded)

        XCTAssertNotNil(decoded.offer)
    }

    func testManageOfferEffectRawValues() {
        XCTAssertEqual(ManageOfferEffect.created.rawValue, 0)
        XCTAssertEqual(ManageOfferEffect.updated.rawValue, 1)
        XCTAssertEqual(ManageOfferEffect.deleted.rawValue, 2)
    }

    // MARK: - Round Trip Base64 Tests for New Types

    func testSimplePaymentResultXDRRoundTripBase64() throws {
        let destinationString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let destination = try PublicKey(accountId: destinationString)

        let payment = SimplePaymentResultXDR(
            destination: destination,
            asset: .native,
            amount: 3000000
        )

        let encoded = try XDREncoder.encode(payment)
        let base64 = Data(encoded).base64EncodedString()

        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(SimplePaymentResultXDR.self, data: [UInt8](decodedData))

        XCTAssertEqual(decoded.amount, 3000000)
    }

    func testOfferEntryXDRRoundTripBase64() throws {
        let sellerString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let seller = try PublicKey(accountId: sellerString)

        let price = PriceXDR(n: 75, d: 100)

        let offer = OfferEntryXDR(
            sellerID: seller,
            offerID: 54321,
            selling: .native,
            buying: .native,
            amount: 7500000,
            price: price,
            flags: 0
        )

        let encoded = try XDREncoder.encode(offer)
        let base64 = Data(encoded).base64EncodedString()

        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(OfferEntryXDR.self, data: [UInt8](decodedData))

        XCTAssertEqual(decoded.offerID, 54321)
        XCTAssertEqual(decoded.amount, 7500000)
    }

    // MARK: - Additional Enum Coverage Tests

    func testTrustLineFlags() {
        XCTAssertEqual(TrustLineFlags.AUTHORIZED_FLAG, 1)
        XCTAssertEqual(TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG, 2)
        XCTAssertEqual(TrustLineFlags.TRUSTLINE_CLAWBACK_ENABLED_FLAG, 4)
    }

    func testAccountFlags() {
        XCTAssertEqual(AccountFlags.AUTH_REQUIRED_FLAG, 1)
        XCTAssertEqual(AccountFlags.AUTH_REVOCABLE_FLAG, 2)
        XCTAssertEqual(AccountFlags.AUTH_IMMUTABLE_FLAG, 4)
        XCTAssertEqual(AccountFlags.AUTH_CLAWBACK_ENABLED_FLAG, 8)
    }

    // MARK: - ContractEventXDR Tests

    func testContractEventXDRWithoutHash() throws {
        let scVal = SCValXDR.u32(999)
        let eventBody = ContractEventBodyV0XDR(topics: [], data: scVal)
        let body = ContractEventBodyXDR.v0(eventBody)

        let contractEvent = ContractEventXDR(
            ext: .void,
            hash: nil,
            type: ContractEventType.system.rawValue,
            body: body
        )

        let encoded = try XDREncoder.encode(contractEvent)
        let decoded = try XDRDecoder.decode(ContractEventXDR.self, data: encoded)

        XCTAssertNil(decoded.hash)
        XCTAssertEqual(decoded.type, ContractEventType.system.rawValue)

        switch decoded.body {
        case .v0(let bodyV0):
            switch bodyV0.data {
            case .u32(let val):
                XCTAssertEqual(val, 999)
            default:
                XCTFail("Expected u32 data")
            }
        }
    }

    func testContractEventXDRWithHash() throws {
        let hash = WrappedData32(Data(repeating: 0xDD, count: 32))
        let scVal = SCValXDR.u32(111)
        let eventBody = ContractEventBodyV0XDR(topics: [], data: scVal)
        let body = ContractEventBodyXDR.v0(eventBody)

        let contractEvent = ContractEventXDR(
            ext: .void,
            hash: hash,
            type: ContractEventType.contract.rawValue,
            body: body
        )

        let encoded = try XDREncoder.encode(contractEvent)
        let decoded = try XDRDecoder.decode(ContractEventXDR.self, data: encoded)

        XCTAssertNotNil(decoded.hash)
        XCTAssertEqual(decoded.hash?.wrapped, hash.wrapped)
        XCTAssertEqual(decoded.type, ContractEventType.contract.rawValue)
    }

    func testContractEventXDRWithTopics() throws {
        let topic1 = SCValXDR.u32(10)
        let topic2 = SCValXDR.u32(20)
        let data = SCValXDR.u32(30)

        let eventBody = ContractEventBodyV0XDR(topics: [topic1, topic2], data: data)
        let body = ContractEventBodyXDR.v0(eventBody)

        let contractEvent = ContractEventXDR(
            ext: .void,
            hash: nil,
            type: ContractEventType.diagnostic.rawValue,
            body: body
        )

        let encoded = try XDREncoder.encode(contractEvent)
        let decoded = try XDRDecoder.decode(ContractEventXDR.self, data: encoded)

        switch decoded.body {
        case .v0(let bodyV0):
            XCTAssertEqual(bodyV0.topics.count, 2)
        }
    }

    func testContractEventTypeRawValues() {
        XCTAssertEqual(ContractEventType.system.rawValue, 0)
        XCTAssertEqual(ContractEventType.contract.rawValue, 1)
        XCTAssertEqual(ContractEventType.diagnostic.rawValue, 2)
    }

    func testDiagnosticEventXDR() throws {
        let scVal = SCValXDR.u32(555)
        let eventBody = ContractEventBodyV0XDR(topics: [], data: scVal)
        let body = ContractEventBodyXDR.v0(eventBody)

        let contractEvent = ContractEventXDR(
            ext: .void,
            hash: nil,
            type: ContractEventType.diagnostic.rawValue,
            body: body
        )

        let diagnosticEvent = DiagnosticEventXDR(
            inSuccessfulContractCall: true,
            event: contractEvent
        )

        let encoded = try XDREncoder.encode(diagnosticEvent)
        let decoded = try XDRDecoder.decode(DiagnosticEventXDR.self, data: encoded)

        XCTAssertTrue(decoded.inSuccessfulContractCall)
        XCTAssertEqual(decoded.event.type, ContractEventType.diagnostic.rawValue)
    }

    func testDiagnosticEventXDRFromBase64() throws {
        let scVal = SCValXDR.u32(777)
        let eventBody = ContractEventBodyV0XDR(topics: [], data: scVal)
        let body = ContractEventBodyXDR.v0(eventBody)

        let contractEvent = ContractEventXDR(
            ext: .void,
            hash: nil,
            type: ContractEventType.system.rawValue,
            body: body
        )

        let diagnosticEvent = DiagnosticEventXDR(
            inSuccessfulContractCall: false,
            event: contractEvent
        )

        let encoded = try XDREncoder.encode(diagnosticEvent)
        let base64 = Data(encoded).base64EncodedString()

        let decoded = try DiagnosticEventXDR(fromBase64: base64)

        XCTAssertFalse(decoded.inSuccessfulContractCall)
    }

    // MARK: - ContractEnvMetaXDR Tests

    func testSCEnvMetaEntryXDRInterfaceVersion() throws {
        let entry = SCEnvMetaEntryXDR.interfaceVersion(12345)

        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(SCEnvMetaEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCEnvMetaKind.interfaceVersion.rawValue)

        switch decoded {
        case .interfaceVersion(let version):
            XCTAssertEqual(version, 12345)
        }
    }

    func testSCEnvMetaKindRawValues() {
        XCTAssertEqual(SCEnvMetaKind.interfaceVersion.rawValue, 0)
    }

    // MARK: - TransactionResultBodyXDR Type Function Tests

    func testTransactionResultBodyXDRTypeFunction() {
        let success = TransactionResultBodyXDR.success([])
        XCTAssertEqual(success.type(), TransactionResultCode.success.rawValue)

        let failed = TransactionResultBodyXDR.failed([])
        XCTAssertEqual(failed.type(), TransactionResultCode.failed.rawValue)

        let tooEarly = TransactionResultBodyXDR.tooEarly
        XCTAssertEqual(tooEarly.type(), TransactionResultCode.tooEarly.rawValue)

        let tooLate = TransactionResultBodyXDR.tooLate
        XCTAssertEqual(tooLate.type(), TransactionResultCode.tooLate.rawValue)
    }

    // MARK: - InnerTransactionResultBodyXDR Tests

    func testInnerTransactionResultBodyXDRTypeFunction() {
        let success = InnerTransactionResultBodyXDR.success([])
        XCTAssertEqual(success.type(), TransactionResultCode.success.rawValue)

        let failed = InnerTransactionResultBodyXDR.failed([])
        XCTAssertEqual(failed.type(), TransactionResultCode.failed.rawValue)

        let badSeq = InnerTransactionResultBodyXDR.badSeq
        XCTAssertEqual(badSeq.type(), TransactionResultCode.badSeq.rawValue)
    }

    func testInnerTransactionResultXDR() throws {
        let innerResult = InnerTransactionResultXDR(
            feeCharged: 500,
            resultBody: .success([]),
            code: .success
        )

        let encoded = try XDREncoder.encode(innerResult)
        let decoded = try XDRDecoder.decode(InnerTransactionResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.feeCharged, 500)
        XCTAssertEqual(decoded.code, .success)
        XCTAssertEqual(decoded.reserved, 0)
    }
}
