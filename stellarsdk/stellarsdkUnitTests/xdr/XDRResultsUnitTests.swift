//
//  XDRResultsUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class XDRResultsUnitTests: XCTestCase {

    // MARK: - Helper Methods

    func createTestPublicKey() throws -> PublicKey {
        return try PublicKey(accountId: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ")
    }

    // MARK: - AccountMergeResultXDR Tests

    func testAccountMergeResultXDRSuccess() throws {
        // Create a success result with source account balance
        let sourceAccountBalance: Int64 = 10000000000 // 1000 XLM in stroops
        let result = AccountMergeResultXDR.sourceAccountBalance(sourceAccountBalance)

        // Encode to XDR
        let encoded = try XDREncoder.encode(result)
        XCTAssertFalse(encoded.isEmpty)

        // Decode from XDR
        let decoded = try XDRDecoder.decode(AccountMergeResultXDR.self, data: encoded)

        // Verify
        switch decoded {
        case .sourceAccountBalance(let balance):
            XCTAssertEqual(balance, sourceAccountBalance)
        default:
            XCTFail("Expected sourceAccountBalance case")
        }
    }

    func testAccountMergeResultXDRMalformed() throws {
        let result = AccountMergeResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AccountMergeResultXDR.self, data: encoded)

        switch decoded {
        case .malformed:
            break
        default:
            XCTFail("Expected malformed case")
        }
    }

    func testAccountMergeResultXDRNoAccount() throws {
        let result = AccountMergeResultXDR.noAccount

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AccountMergeResultXDR.self, data: encoded)

        switch decoded {
        case .noAccount:
            break
        default:
            XCTFail("Expected noAccount case")
        }
    }

    func testAccountMergeResultXDRImmutableSet() throws {
        let result = AccountMergeResultXDR.immutableSet

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AccountMergeResultXDR.self, data: encoded)

        switch decoded {
        case .immutableSet:
            break
        default:
            XCTFail("Expected immutableSet case")
        }
    }

    func testAccountMergeResultXDRHasSubEntries() throws {
        let result = AccountMergeResultXDR.hasSubEntries

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AccountMergeResultXDR.self, data: encoded)

        switch decoded {
        case .hasSubEntries:
            break
        default:
            XCTFail("Expected hasSubEntries case")
        }
    }

    func testAccountMergeResultXDRSeqnumTooFar() throws {
        let result = AccountMergeResultXDR.seqnumTooFar

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AccountMergeResultXDR.self, data: encoded)

        switch decoded {
        case .seqnumTooFar:
            break
        default:
            XCTFail("Expected seqnumTooFar case")
        }
    }

    func testAccountMergeResultXDRDestinationFull() throws {
        let result = AccountMergeResultXDR.destFull

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AccountMergeResultXDR.self, data: encoded)

        switch decoded {
        case .destFull:
            break
        default:
            XCTFail("Expected destFull case")
        }
    }

    func testAccountMergeResultXDRIsSponsor() throws {
        let result = AccountMergeResultXDR.isSponsor

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AccountMergeResultXDR.self, data: encoded)

        switch decoded {
        case .isSponsor:
            break
        default:
            XCTFail("Expected isSponsor case")
        }
    }

    // MARK: - AllowTrustResultXDR Tests

    func testAllowTrustResultXDRSuccess() throws {
        let result = AllowTrustResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AllowTrustResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testAllowTrustResultXDRMalformed() throws {
        let result = AllowTrustResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AllowTrustResultXDR.self, data: encoded)

        switch decoded {
        case .malformed:
            break
        default:
            XCTFail("Expected malformed case")
        }
    }

    func testAllowTrustResultXDRNoTrustline() throws {
        let result = AllowTrustResultXDR.noTrustLine

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AllowTrustResultXDR.self, data: encoded)

        switch decoded {
        case .noTrustLine:
            break
        default:
            XCTFail("Expected noTrustLine case")
        }
    }

    func testAllowTrustResultXDRTrustNotRequired() throws {
        let result = AllowTrustResultXDR.trustNotRequired

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AllowTrustResultXDR.self, data: encoded)

        switch decoded {
        case .trustNotRequired:
            break
        default:
            XCTFail("Expected trustNotRequired case")
        }
    }

    func testAllowTrustResultXDRCantRevoke() throws {
        let result = AllowTrustResultXDR.cantRevoke

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AllowTrustResultXDR.self, data: encoded)

        switch decoded {
        case .cantRevoke:
            break
        default:
            XCTFail("Expected cantRevoke case")
        }
    }

    func testAllowTrustResultXDRSelfNotAllowed() throws {
        let result = AllowTrustResultXDR.selfNotAllowed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AllowTrustResultXDR.self, data: encoded)

        switch decoded {
        case .selfNotAllowed:
            break
        default:
            XCTFail("Expected selfNotAllowed case")
        }
    }

    func testAllowTrustResultXDRLowReserve() throws {
        let result = AllowTrustResultXDR.lowReserve

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AllowTrustResultXDR.self, data: encoded)

        switch decoded {
        case .lowReserve:
            break
        default:
            XCTFail("Expected lowReserve case")
        }
    }

    // MARK: - BeginSponsoringFutureReservesResultXDR Tests

    func testBeginSponsoringFutureReservesResultXDRSuccess() throws {
        let result = BeginSponsoringFutureReservesResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(BeginSponsoringFutureReservesResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testBeginSponsoringFutureReservesResultXDRMalformed() throws {
        let result = BeginSponsoringFutureReservesResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(BeginSponsoringFutureReservesResultXDR.self, data: encoded)

        switch decoded {
        case .malformed:
            break
        default:
            XCTFail("Expected malformed case")
        }
    }

    func testBeginSponsoringFutureReservesResultXDRAlreadySponsored() throws {
        let result = BeginSponsoringFutureReservesResultXDR.alreadySponsored

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(BeginSponsoringFutureReservesResultXDR.self, data: encoded)

        switch decoded {
        case .alreadySponsored:
            break
        default:
            XCTFail("Expected alreadySponsored case")
        }
    }

    func testBeginSponsoringFutureReservesResultXDRRecursive() throws {
        let result = BeginSponsoringFutureReservesResultXDR.recursive

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(BeginSponsoringFutureReservesResultXDR.self, data: encoded)

        switch decoded {
        case .recursive:
            break
        default:
            XCTFail("Expected recursive case")
        }
    }

    // MARK: - BumpSequenceResultXDR Tests

    func testBumpSequenceResultXDRSuccess() throws {
        let result = BumpSequenceResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(BumpSequenceResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testBumpSequenceResultXDRBadSeq() throws {
        let result = BumpSequenceResultXDR.badSeq

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(BumpSequenceResultXDR.self, data: encoded)

        switch decoded {
        case .badSeq:
            break
        default:
            XCTFail("Expected badSeq case")
        }
    }

    // MARK: - ClaimClaimableBalanceResultXDR Tests

    func testClaimClaimableBalanceResultXDRSuccess() throws {
        let result = ClaimClaimableBalanceResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClaimClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testClaimClaimableBalanceResultXDRDoesNotExist() throws {
        let result = ClaimClaimableBalanceResultXDR.doesNotExist

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClaimClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .doesNotExist:
            break
        default:
            XCTFail("Expected doesNotExist case")
        }
    }

    func testClaimClaimableBalanceResultXDRCannotClaim() throws {
        let result = ClaimClaimableBalanceResultXDR.cannotClaim

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClaimClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .cannotClaim:
            break
        default:
            XCTFail("Expected cannotClaim case")
        }
    }

    func testClaimClaimableBalanceResultXDRLineFill() throws {
        let result = ClaimClaimableBalanceResultXDR.lineFull

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClaimClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .lineFull:
            break
        default:
            XCTFail("Expected lineFull case")
        }
    }

    func testClaimClaimableBalanceResultXDRNoTrust() throws {
        let result = ClaimClaimableBalanceResultXDR.noTrust

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClaimClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .noTrust:
            break
        default:
            XCTFail("Expected noTrust case")
        }
    }

    func testClaimClaimableBalanceResultXDRNotAuthorized() throws {
        let result = ClaimClaimableBalanceResultXDR.notAuthorized

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClaimClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .notAuthorized:
            break
        default:
            XCTFail("Expected notAuthorized case")
        }
    }

    // MARK: - ClawbackClaimableBalanceResultXDR Tests

    func testClawbackClaimableBalanceResultXDRSuccess() throws {
        let result = ClawbackClaimableBalanceResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClawbackClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testClawbackClaimableBalanceResultXDRDoesNotExist() throws {
        let result = ClawbackClaimableBalanceResultXDR.doesNotExist

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClawbackClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .doesNotExist:
            break
        default:
            XCTFail("Expected doesNotExist case")
        }
    }

    func testClawbackClaimableBalanceResultXDRNotIssuer() throws {
        let result = ClawbackClaimableBalanceResultXDR.notIssuer

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClawbackClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .notIssuer:
            break
        default:
            XCTFail("Expected notIssuer case")
        }
    }

    func testClawbackClaimableBalanceResultXDRNotClawbackEnabled() throws {
        let result = ClawbackClaimableBalanceResultXDR.notClawbackEnabled

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClawbackClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .notClawbackEnabled:
            break
        default:
            XCTFail("Expected notClawbackEnabled case")
        }
    }

    // MARK: - ClawbackResultXDR Tests

    func testClawbackResultXDRSuccess() throws {
        let result = ClawbackResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClawbackResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testClawbackResultXDRMalformed() throws {
        let result = ClawbackResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClawbackResultXDR.self, data: encoded)

        switch decoded {
        case .malformed:
            break
        default:
            XCTFail("Expected malformed case")
        }
    }

    func testClawbackResultXDRNotClawbackEnabled() throws {
        let result = ClawbackResultXDR.notClawbackEnabled

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClawbackResultXDR.self, data: encoded)

        switch decoded {
        case .notClawbackEnabled:
            break
        default:
            XCTFail("Expected notClawbackEnabled case")
        }
    }

    func testClawbackResultXDRNoTrust() throws {
        let result = ClawbackResultXDR.noTrust

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClawbackResultXDR.self, data: encoded)

        switch decoded {
        case .noTrust:
            break
        default:
            XCTFail("Expected noTrust case")
        }
    }

    func testClawbackResultXDRUnderfunded() throws {
        let result = ClawbackResultXDR.underfunded

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ClawbackResultXDR.self, data: encoded)

        switch decoded {
        case .underfunded:
            break
        default:
            XCTFail("Expected underfunded case")
        }
    }

    // MARK: - CreateAccountResultXDR Tests

    func testCreateAccountResultXDRSuccess() throws {
        let result = CreateAccountResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(CreateAccountResultXDR.self, data: encoded)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testCreateAccountResultXDRMalformed() throws {
        let result = CreateAccountResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(CreateAccountResultXDR.self, data: encoded)

        switch decoded {
        case .malformed:
            break
        default:
            XCTFail("Expected malformed case")
        }
    }

    func testCreateAccountResultXDRUnderfunded() throws {
        let result = CreateAccountResultXDR.underfunded

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(CreateAccountResultXDR.self, data: encoded)

        switch decoded {
        case .underfunded:
            break
        default:
            XCTFail("Expected underfunded case")
        }
    }

    func testCreateAccountResultXDRLowReserve() throws {
        let result = CreateAccountResultXDR.lowReserve

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(CreateAccountResultXDR.self, data: encoded)

        switch decoded {
        case .lowReserve:
            break
        default:
            XCTFail("Expected lowReserve case")
        }
    }

    func testCreateAccountResultXDRAlreadyExists() throws {
        let result = CreateAccountResultXDR.alreadyExist

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(CreateAccountResultXDR.self, data: encoded)

        switch decoded {
        case .alreadyExist:
            break
        default:
            XCTFail("Expected alreadyExist case")
        }
    }

    // MARK: - CreateClaimableBalanceResultXDR Tests

    func testCreateClaimableBalanceResultXDRSuccess() throws {
        // Create a valid balance ID (32 bytes of test data)
        let balanceIdHex = "da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be"
        let claimableBalanceId = try ClaimableBalanceIDXDR(claimableBalanceId: balanceIdHex)

        let result = CreateClaimableBalanceResultXDR.balanceID(claimableBalanceId)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .balanceID(let balanceId):
            // Verify the balance ID was preserved
            XCTAssertEqual(balanceId.claimableBalanceIdString, claimableBalanceId.claimableBalanceIdString)
        default:
            XCTFail("Expected balanceID case")
        }
    }

    func testCreateClaimableBalanceResultXDRMalformed() throws {
        let result = CreateClaimableBalanceResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .malformed:
            break
        default:
            XCTFail("Expected malformed case")
        }
    }

    func testCreateClaimableBalanceResultXDRLowReserve() throws {
        let result = CreateClaimableBalanceResultXDR.lowReserve

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .lowReserve:
            break
        default:
            XCTFail("Expected lowReserve case")
        }
    }

    func testCreateClaimableBalanceResultXDRNoTrust() throws {
        let result = CreateClaimableBalanceResultXDR.noTrust

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .noTrust:
            break
        default:
            XCTFail("Expected noTrust case")
        }
    }

    func testCreateClaimableBalanceResultXDRNotAuthorized() throws {
        let result = CreateClaimableBalanceResultXDR.notAuthorized

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .notAuthorized:
            break
        default:
            XCTFail("Expected notAuthorized case")
        }
    }

    func testCreateClaimableBalanceResultXDRUnderfunded() throws {
        let result = CreateClaimableBalanceResultXDR.underfunded

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(CreateClaimableBalanceResultXDR.self, data: encoded)

        switch decoded {
        case .underfunded:
            break
        default:
            XCTFail("Expected underfunded case")
        }
    }

    // MARK: - DataEntryXDR Tests

    func testDataEntryXDREncodingDecoding() throws {
        // Create a public key from a known account ID
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        let dataName = "test_data_key"
        let dataValue = Data([0x01, 0x02, 0x03, 0x04, 0x05])

        let dataEntry = DataEntryXDR(accountID: publicKey, dataName: dataName, dataValue: dataValue)

        let encoded = try XDREncoder.encode(dataEntry)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(DataEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.accountID.accountId, accountIdString)
        XCTAssertEqual(decoded.dataName, dataName)
        XCTAssertEqual(decoded.dataValue, dataValue)
        XCTAssertEqual(decoded.reserved, 0)
    }

    func testDataEntryXDRWithEmptyData() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        let dataName = "empty_data"
        let dataValue = Data()

        let dataEntry = DataEntryXDR(accountID: publicKey, dataName: dataName, dataValue: dataValue)

        let encoded = try XDREncoder.encode(dataEntry)
        let decoded = try XDRDecoder.decode(DataEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.accountID.accountId, accountIdString)
        XCTAssertEqual(decoded.dataName, dataName)
        XCTAssertEqual(decoded.dataValue, dataValue)
    }

    func testDataEntryXDRWithLongDataName() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        let dataName = "this_is_a_longer_data_entry_name_for_testing"
        let dataValue = Data([0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF])

        let dataEntry = DataEntryXDR(accountID: publicKey, dataName: dataName, dataValue: dataValue)

        let encoded = try XDREncoder.encode(dataEntry)
        let decoded = try XDRDecoder.decode(DataEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.dataName, dataName)
        XCTAssertEqual(decoded.dataValue, dataValue)
    }

    func testDataEntryXDRWithLargeDataValue() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        let dataName = "large_data"
        // Create a 64-byte data value (maximum allowed for manage data)
        let dataValue = Data(repeating: 0x42, count: 64)

        let dataEntry = DataEntryXDR(accountID: publicKey, dataName: dataName, dataValue: dataValue)

        let encoded = try XDREncoder.encode(dataEntry)
        let decoded = try XDRDecoder.decode(DataEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.dataName, dataName)
        XCTAssertEqual(decoded.dataValue, dataValue)
        XCTAssertEqual(decoded.dataValue.count, 64)
    }

    // MARK: - AccountMergeResultCode Enum Tests

    func testAccountMergeResultCodeRawValues() {
        XCTAssertEqual(AccountMergeResultCode.success.rawValue, 0)
        XCTAssertEqual(AccountMergeResultCode.malformed.rawValue, -1)
        XCTAssertEqual(AccountMergeResultCode.noAccount.rawValue, -2)
        XCTAssertEqual(AccountMergeResultCode.immutableSet.rawValue, -3)
        XCTAssertEqual(AccountMergeResultCode.hasSubEntries.rawValue, -4)
        XCTAssertEqual(AccountMergeResultCode.seqnumTooFar.rawValue, -5)
        XCTAssertEqual(AccountMergeResultCode.destFull.rawValue, -6)
        XCTAssertEqual(AccountMergeResultCode.isSponsor.rawValue, -7)
    }

    // MARK: - AllowTrustResultCode Enum Tests

    func testAllowTrustResultCodeRawValues() {
        XCTAssertEqual(AllowTrustResultCode.success.rawValue, 0)
        XCTAssertEqual(AllowTrustResultCode.malformed.rawValue, -1)
        XCTAssertEqual(AllowTrustResultCode.noTrustLine.rawValue, -2)
        XCTAssertEqual(AllowTrustResultCode.trustNotRequired.rawValue, -3)
        XCTAssertEqual(AllowTrustResultCode.cantRevoke.rawValue, -4)
        XCTAssertEqual(AllowTrustResultCode.selfNotAllowed.rawValue, -5)
        XCTAssertEqual(AllowTrustResultCode.lowReserve.rawValue, -6)
    }

    // MARK: - BeginSponsoringFutureReservesResultCode Enum Tests

    func testBeginSponsoringFutureReservesResultCodeRawValues() {
        XCTAssertEqual(BeginSponsoringFutureReservesResultCode.success.rawValue, 0)
        XCTAssertEqual(BeginSponsoringFutureReservesResultCode.malformed.rawValue, -1)
        XCTAssertEqual(BeginSponsoringFutureReservesResultCode.alreadySponsored.rawValue, -2)
        XCTAssertEqual(BeginSponsoringFutureReservesResultCode.recursive.rawValue, -3)
    }

    // MARK: - BumpSequenceResultCode Enum Tests

    func testBumpSequenceResultCodeRawValues() {
        XCTAssertEqual(BumpSequenceResultCode.success.rawValue, 0)
        XCTAssertEqual(BumpSequenceResultCode.badSeq.rawValue, -1)
    }

    // MARK: - ClaimClaimableBalanceResultCode Enum Tests

    func testClaimClaimableBalanceResultCodeRawValues() {
        XCTAssertEqual(ClaimClaimableBalanceResultCode.success.rawValue, 0)
        XCTAssertEqual(ClaimClaimableBalanceResultCode.doesNotExist.rawValue, -1)
        XCTAssertEqual(ClaimClaimableBalanceResultCode.cannotClaim.rawValue, -2)
        XCTAssertEqual(ClaimClaimableBalanceResultCode.lineFull.rawValue, -3)
        XCTAssertEqual(ClaimClaimableBalanceResultCode.noTrust.rawValue, -4)
        XCTAssertEqual(ClaimClaimableBalanceResultCode.notAuthorized.rawValue, -5)
    }

    // MARK: - ClawbackClaimableBalanceResultCode Enum Tests

    func testClawbackClaimableBalanceResultCodeRawValues() {
        XCTAssertEqual(ClawbackClaimableBalanceResultCode.success.rawValue, 0)
        XCTAssertEqual(ClawbackClaimableBalanceResultCode.doesNotExist.rawValue, -1)
        XCTAssertEqual(ClawbackClaimableBalanceResultCode.notIssuer.rawValue, -2)
        XCTAssertEqual(ClawbackClaimableBalanceResultCode.notClawbackEnabled.rawValue, -3)
    }

    // MARK: - ClawbackResultCode Enum Tests

    func testClawbackResultCodeRawValues() {
        XCTAssertEqual(ClawbackResultCode.success.rawValue, 0)
        XCTAssertEqual(ClawbackResultCode.malformed.rawValue, -1)
        XCTAssertEqual(ClawbackResultCode.notClawbackEnabled.rawValue, -2)
        XCTAssertEqual(ClawbackResultCode.noTrust.rawValue, -3)
        XCTAssertEqual(ClawbackResultCode.underfunded.rawValue, -4)
    }

    // MARK: - CreateAccountResultCode Enum Tests

    func testCreateAccountResultCodeRawValues() {
        XCTAssertEqual(CreateAccountResultCode.success.rawValue, 0)
        XCTAssertEqual(CreateAccountResultCode.malformed.rawValue, -1)
        XCTAssertEqual(CreateAccountResultCode.underfunded.rawValue, -2)
        XCTAssertEqual(CreateAccountResultCode.lowReserve.rawValue, -3)
        XCTAssertEqual(CreateAccountResultCode.alreadyExist.rawValue, -4)
    }

    // MARK: - CreateClaimableBalanceResultCode Enum Tests

    func testCreateClaimableBalanceResultCodeRawValues() {
        XCTAssertEqual(CreateClaimableBalanceResultCode.success.rawValue, 0)
        XCTAssertEqual(CreateClaimableBalanceResultCode.malformed.rawValue, -1)
        XCTAssertEqual(CreateClaimableBalanceResultCode.lowReserve.rawValue, -2)
        XCTAssertEqual(CreateClaimableBalanceResultCode.noTrust.rawValue, -3)
        XCTAssertEqual(CreateClaimableBalanceResultCode.notAuthorized.rawValue, -4)
        XCTAssertEqual(CreateClaimableBalanceResultCode.underfunded.rawValue, -5)
    }

    // MARK: - Round Trip Tests with Base64

    func testAccountMergeResultRoundTripBase64() throws {
        let sourceBalance: Int64 = 5000000000
        let result = AccountMergeResultXDR.sourceAccountBalance(sourceBalance)

        // Encode to base64
        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        // Decode from base64
        let decoded = try AccountMergeResultXDR(xdr: base64)

        switch decoded {
        case .sourceAccountBalance(let balance):
            XCTAssertEqual(balance, sourceBalance)
        default:
            XCTFail("Expected sourceAccountBalance case")
        }
    }

    func testCreateAccountResultRoundTripBase64() throws {
        let result = CreateAccountResultXDR.success

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try CreateAccountResultXDR(xdr: base64)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testBumpSequenceResultRoundTripBase64() throws {
        let result = BumpSequenceResultXDR.success

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try BumpSequenceResultXDR(xdr: base64)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testAllowTrustResultRoundTripBase64() throws {
        let result = AllowTrustResultXDR.success

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try AllowTrustResultXDR(xdr: base64)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testClawbackResultRoundTripBase64() throws {
        let result = ClawbackResultXDR.success

        guard let base64 = result.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try ClawbackResultXDR(xdr: base64)

        switch decoded {
        case .success:
            break
        default:
            XCTFail("Expected success case")
        }
    }

    func testDataEntryRoundTripBase64() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        let dataEntry = DataEntryXDR(
            accountID: publicKey,
            dataName: "test_key",
            dataValue: Data([0x01, 0x02, 0x03])
        )

        guard let base64 = dataEntry.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try DataEntryXDR(xdr: base64)

        XCTAssertEqual(decoded.accountID.accountId, accountIdString)
        XCTAssertEqual(decoded.dataName, "test_key")
        XCTAssertEqual(decoded.dataValue, Data([0x01, 0x02, 0x03]))
    }

    // MARK: - Edge Case Tests

    func testAccountMergeResultWithZeroBalance() throws {
        let result = AccountMergeResultXDR.sourceAccountBalance(0)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AccountMergeResultXDR.self, data: encoded)

        switch decoded {
        case .sourceAccountBalance(let balance):
            XCTAssertEqual(balance, 0)
        default:
            XCTFail("Expected sourceAccountBalance case")
        }
    }

    func testAccountMergeResultWithMaxBalance() throws {
        let maxBalance = Int64.max
        let result = AccountMergeResultXDR.sourceAccountBalance(maxBalance)

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(AccountMergeResultXDR.self, data: encoded)

        switch decoded {
        case .sourceAccountBalance(let balance):
            XCTAssertEqual(balance, maxBalance)
        default:
            XCTFail("Expected sourceAccountBalance case")
        }
    }

    func testDataEntryWithSpecialCharactersInName() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        let dataName = "test_data.key-name"
        let dataValue = Data([0xFF, 0x00, 0xFE, 0x01])

        let dataEntry = DataEntryXDR(accountID: publicKey, dataName: dataName, dataValue: dataValue)

        let encoded = try XDREncoder.encode(dataEntry)
        let decoded = try XDRDecoder.decode(DataEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.dataName, dataName)
        XCTAssertEqual(decoded.dataValue, dataValue)
    }

    // MARK: - ClaimableBalanceIDXDR Tests

    func testClaimableBalanceIDXDREncodingDecoding() throws {
        let balanceIdHex = "da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be"
        let claimableBalanceId = try ClaimableBalanceIDXDR(claimableBalanceId: balanceIdHex)

        let encoded = try XDREncoder.encode(claimableBalanceId)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(ClaimableBalanceIDXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)
        XCTAssertEqual(decoded.claimableBalanceIdString, claimableBalanceId.claimableBalanceIdString)
    }

    func testClaimableBalanceIDXDRRoundTripBase64() throws {
        let balanceIdHex = "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
        let claimableBalanceId = try ClaimableBalanceIDXDR(claimableBalanceId: balanceIdHex)

        guard let base64 = claimableBalanceId.xdrEncoded else {
            XCTFail("Failed to encode to base64")
            return
        }

        let decoded = try ClaimableBalanceIDXDR(xdr: base64)

        XCTAssertEqual(decoded.type(), ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)
        XCTAssertEqual(decoded.claimableBalanceIdString, claimableBalanceId.claimableBalanceIdString)
    }

    // MARK: - Error Case Tests

    func testPaymentResultXDRAllErrorCases() throws {
        // Test all PaymentResultCode error cases by constructing and round-tripping each
        let errorCases: [(PaymentResultXDR, String)] = [
            (.malformed, "malformed"),
            (.underfunded, "underfunded"),
            (.srcNoTrust, "srcNoTrust"),
            (.srcNotAuthorized, "srcNotAuthorized"),
            (.noDestination, "noDestination"),
            (.noTrust, "noTrust"),
            (.notAuthorized, "notAuthorized"),
            (.lineFull, "lineFull"),
            (.noIssuer, "noIssuer")
        ]

        for (errorResult, name) in errorCases {
            let encoded = try XDREncoder.encode(errorResult)
            XCTAssertFalse(encoded.isEmpty, "Encoding failed for \(name)")

            let decoded = try XDRDecoder.decode(PaymentResultXDR.self, data: encoded)

            switch (errorResult, decoded) {
            case (.malformed, .malformed),
                 (.underfunded, .underfunded),
                 (.srcNoTrust, .srcNoTrust),
                 (.srcNotAuthorized, .srcNotAuthorized),
                 (.noDestination, .noDestination),
                 (.noTrust, .noTrust),
                 (.notAuthorized, .notAuthorized),
                 (.lineFull, .lineFull),
                 (.noIssuer, .noIssuer):
                break
            default:
                XCTFail("Round-trip mismatch for \(name)")
            }
        }
    }

    func testCreateAccountResultXDRAllErrorCases() throws {
        // Test all CreateAccountResultCode error cases
        let errorCases: [(CreateAccountResultXDR, String)] = [
            (.malformed, "malformed"),
            (.underfunded, "underfunded"),
            (.lowReserve, "lowReserve"),
            (.alreadyExist, "alreadyExist")
        ]

        for (errorResult, name) in errorCases {
            let encoded = try XDREncoder.encode(errorResult)
            XCTAssertFalse(encoded.isEmpty, "Encoding failed for \(name)")

            let decoded = try XDRDecoder.decode(CreateAccountResultXDR.self, data: encoded)

            switch (errorResult, decoded) {
            case (.malformed, .malformed),
                 (.underfunded, .underfunded),
                 (.lowReserve, .lowReserve),
                 (.alreadyExist, .alreadyExist):
                break
            default:
                XCTFail("Round-trip mismatch for \(name)")
            }
        }
    }

    func testPathPaymentStrictReceiveResultXDRAllErrorCases() throws {
        let errorCases: [(PathPaymentResultXDR, String)] = [
            (.malformed, "malformed"),
            (.underfunded, "underfunded"),
            (.srcNoTrust, "srcNoTrust"),
            (.srcNotAuthorized, "srcNotAuthorized"),
            (.noDestination, "noDestination"),
            (.noTrust, "noTrust"),
            (.notAuthorized, "notAuthorized"),
            (.lineFull, "lineFull"),
            (.tooFewOffers, "tooFewOffers"),
            (.offerCrossSelf, "offerCrossSelf"),
            (.overSendmax, "overSendmax")
        ]

        for (errorResult, name) in errorCases {
            let encoded = try XDREncoder.encode(errorResult)
            XCTAssertFalse(encoded.isEmpty, "Encoding failed for \(name)")

            let decoded = try XDRDecoder.decode(PathPaymentResultXDR.self, data: encoded)

            switch (errorResult, decoded) {
            case (.malformed, .malformed),
                 (.underfunded, .underfunded),
                 (.srcNoTrust, .srcNoTrust),
                 (.srcNotAuthorized, .srcNotAuthorized),
                 (.noDestination, .noDestination),
                 (.noTrust, .noTrust),
                 (.notAuthorized, .notAuthorized),
                 (.lineFull, .lineFull),
                 (.tooFewOffers, .tooFewOffers),
                 (.offerCrossSelf, .offerCrossSelf),
                 (.overSendmax, .overSendmax):
                break
            default:
                XCTFail("Round-trip mismatch for \(name)")
            }
        }
    }

    func testPathPaymentStrictSendResultXDRAllErrorCases() throws {
        let errorCases: [(PathPaymentResultXDR, String)] = [
            (.malformed, "malformed"),
            (.underfunded, "underfunded"),
            (.srcNoTrust, "srcNoTrust"),
            (.srcNotAuthorized, "srcNotAuthorized"),
            (.noDestination, "noDestination"),
            (.noTrust, "noTrust"),
            (.notAuthorized, "notAuthorized"),
            (.lineFull, "lineFull"),
            (.tooFewOffers, "tooFewOffers"),
            (.offerCrossSelf, "offerCrossSelf"),
            (.overSendmax, "overSendmax")
        ]

        for (errorResult, name) in errorCases {
            let encoded = try XDREncoder.encode(errorResult)
            XCTAssertFalse(encoded.isEmpty, "Encoding failed for \(name)")

            let decoded = try XDRDecoder.decode(PathPaymentResultXDR.self, data: encoded)

            switch (errorResult, decoded) {
            case (.malformed, .malformed),
                 (.underfunded, .underfunded),
                 (.srcNoTrust, .srcNoTrust),
                 (.srcNotAuthorized, .srcNotAuthorized),
                 (.noDestination, .noDestination),
                 (.noTrust, .noTrust),
                 (.notAuthorized, .notAuthorized),
                 (.lineFull, .lineFull),
                 (.tooFewOffers, .tooFewOffers),
                 (.offerCrossSelf, .offerCrossSelf),
                 (.overSendmax, .overSendmax):
                break
            default:
                XCTFail("Round-trip mismatch for \(name)")
            }
        }
    }

    func testManageSellOfferResultXDRAllErrorCases() throws {
        // Test key ManageOfferResultCode error cases (used for sell offers)
        let errorCases: [(ManageOfferResultCode, String)] = [
            (.malformed, "malformed"),
            (.sellNoTrust, "sellNoTrust"),
            (.buyNoTrust, "buyNoTrust"),
            (.sellNotAuthorized, "sellNotAuthorized"),
            (.buyNotAuthorized, "buyNotAuthorized"),
            (.lineFull, "lineFull"),
            (.underfunded, "underfunded"),
            (.crossSelf, "crossSelf"),
            (.sellNoIssuer, "sellNoIssuer"),
            (.buyNoIssuer, "buyNoIssuer"),
            (.notFound, "notFound"),
            (.lowReserve, "lowReserve")
        ]

        for (errorCode, name) in errorCases {
            let result = ManageOfferResultXDR.empty(errorCode.rawValue)

            let encoded = try XDREncoder.encode(result)
            XCTAssertFalse(encoded.isEmpty, "Encoding failed for \(name)")

            let decoded = try XDRDecoder.decode(ManageOfferResultXDR.self, data: encoded)

            switch decoded {
            case .success:
                XCTFail("Expected empty case for \(name), got success")
            case .empty(let code):
                XCTAssertEqual(code, errorCode.rawValue, "Error code mismatch for \(name)")
            }
        }
    }

    func testManageBuyOfferResultXDRAllErrorCases() throws {
        // Test key ManageOfferResultCode error cases (used for buy offers)
        let errorCases: [(ManageOfferResultCode, String)] = [
            (.malformed, "malformed"),
            (.sellNoTrust, "sellNoTrust"),
            (.buyNoTrust, "buyNoTrust"),
            (.sellNotAuthorized, "sellNotAuthorized"),
            (.buyNotAuthorized, "buyNotAuthorized"),
            (.lineFull, "lineFull"),
            (.underfunded, "underfunded"),
            (.crossSelf, "crossSelf"),
            (.sellNoIssuer, "sellNoIssuer"),
            (.buyNoIssuer, "buyNoIssuer"),
            (.notFound, "notFound"),
            (.lowReserve, "lowReserve")
        ]

        for (errorCode, name) in errorCases {
            let result = ManageOfferResultXDR.empty(errorCode.rawValue)

            let encoded = try XDREncoder.encode(result)
            XCTAssertFalse(encoded.isEmpty, "Encoding failed for \(name)")

            let decoded = try XDRDecoder.decode(ManageOfferResultXDR.self, data: encoded)

            switch decoded {
            case .success:
                XCTFail("Expected empty case for \(name), got success")
            case .empty(let code):
                XCTAssertEqual(code, errorCode.rawValue, "Error code mismatch for \(name)")
            }
        }
    }

    func testSetOptionsResultXDRAllErrorCases() throws {
        // Test all SetOptionsResultCode error cases
        let errorCases: [(SetOptionsResultXDR, String)] = [
            (.lowReserve, "lowReserve"),
            (.tooManySigners, "tooManySigners"),
            (.badFlags, "badFlags"),
            (.invalidInflation, "invalidInflation"),
            (.cantChange, "cantChange"),
            (.unknownFlag, "unknownFlag"),
            (.thresholdOutOfRange, "thresholdOutOfRange"),
            (.badSigner, "badSigner"),
            (.invalidHomeDomain, "invalidHomeDomain")
        ]

        for (errorResult, name) in errorCases {
            let encoded = try XDREncoder.encode(errorResult)
            XCTAssertFalse(encoded.isEmpty, "Encoding failed for \(name)")

            let decoded = try XDRDecoder.decode(SetOptionsResultXDR.self, data: encoded)

            switch (errorResult, decoded) {
            case (.lowReserve, .lowReserve),
                 (.tooManySigners, .tooManySigners),
                 (.badFlags, .badFlags),
                 (.invalidInflation, .invalidInflation),
                 (.cantChange, .cantChange),
                 (.unknownFlag, .unknownFlag),
                 (.thresholdOutOfRange, .thresholdOutOfRange),
                 (.badSigner, .badSigner),
                 (.invalidHomeDomain, .invalidHomeDomain):
                break
            default:
                XCTFail("Round-trip mismatch for \(name)")
            }
        }
    }

    func testChangeTrustResultXDRAllErrorCases() throws {
        // Test all ChangeTrustResultCode error cases
        let errorCases: [(ChangeTrustResultXDR, String)] = [
            (.malformed, "malformed"),
            (.noIssuer, "noIssuer"),
            (.invalidLimit, "invalidLimit"),
            (.lowReserve, "lowReserve"),
            (.selfNotAllowed, "selfNotAllowed"),
            (.trustLineMissing, "trustLineMissing"),
            (.cannotDelete, "cannotDelete"),
            (.notAuthMaintainLiabilities, "notAuthMaintainLiabilities")
        ]

        for (errorResult, name) in errorCases {
            let encoded = try XDREncoder.encode(errorResult)
            XCTAssertFalse(encoded.isEmpty, "Encoding failed for \(name)")

            let decoded = try XDRDecoder.decode(ChangeTrustResultXDR.self, data: encoded)

            switch (errorResult, decoded) {
            case (.malformed, .malformed),
                 (.noIssuer, .noIssuer),
                 (.invalidLimit, .invalidLimit),
                 (.lowReserve, .lowReserve),
                 (.selfNotAllowed, .selfNotAllowed),
                 (.trustLineMissing, .trustLineMissing),
                 (.cannotDelete, .cannotDelete),
                 (.notAuthMaintainLiabilities, .notAuthMaintainLiabilities):
                break
            default:
                XCTFail("Round-trip mismatch for \(name)")
            }
        }
    }

    func testAllowTrustResultXDRAllErrorCases() throws {
        // Test all AllowTrustResultCode error cases
        let errorCases: [(AllowTrustResultXDR, String)] = [
            (.malformed, "malformed"),
            (.noTrustLine, "noTrustLine"),
            (.trustNotRequired, "trustNotRequired"),
            (.cantRevoke, "cantRevoke"),
            (.selfNotAllowed, "selfNotAllowed"),
            (.lowReserve, "lowReserve")
        ]

        for (errorResult, name) in errorCases {
            let encoded = try XDREncoder.encode(errorResult)
            XCTAssertFalse(encoded.isEmpty, "Encoding failed for \(name)")

            let decoded = try XDRDecoder.decode(AllowTrustResultXDR.self, data: encoded)

            switch (errorResult, decoded) {
            case (.malformed, .malformed),
                 (.noTrustLine, .noTrustLine),
                 (.trustNotRequired, .trustNotRequired),
                 (.cantRevoke, .cantRevoke),
                 (.selfNotAllowed, .selfNotAllowed),
                 (.lowReserve, .lowReserve):
                break
            default:
                XCTFail("Round-trip mismatch for \(name)")
            }
        }
    }

    func testAccountMergeResultXDRAllErrorCases() throws {
        // Test all AccountMergeResultCode error cases
        let errorCases: [(AccountMergeResultXDR, String)] = [
            (.malformed, "malformed"),
            (.noAccount, "noAccount"),
            (.immutableSet, "immutableSet"),
            (.hasSubEntries, "hasSubEntries"),
            (.seqnumTooFar, "seqnumTooFar"),
            (.destFull, "destFull"),
            (.isSponsor, "isSponsor")
        ]

        for (errorResult, name) in errorCases {
            let encoded = try XDREncoder.encode(errorResult)
            XCTAssertFalse(encoded.isEmpty, "Encoding failed for \(name)")

            let decoded = try XDRDecoder.decode(AccountMergeResultXDR.self, data: encoded)

            switch (errorResult, decoded) {
            case (.malformed, .malformed),
                 (.noAccount, .noAccount),
                 (.immutableSet, .immutableSet),
                 (.hasSubEntries, .hasSubEntries),
                 (.seqnumTooFar, .seqnumTooFar),
                 (.destFull, .destFull),
                 (.isSponsor, .isSponsor):
                break
            default:
                XCTFail("Round-trip mismatch for \(name)")
            }
        }
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

    func testOperationResultCodeAllValues() {
        XCTAssertEqual(OperationResultCode.inner.rawValue, 0)
        XCTAssertEqual(OperationResultCode.badAuth.rawValue, -1)
        XCTAssertEqual(OperationResultCode.noAccount.rawValue, -2)
        XCTAssertEqual(OperationResultCode.notSupported.rawValue, -3)
        XCTAssertEqual(OperationResultCode.tooManySubentries.rawValue, -4)
        XCTAssertEqual(OperationResultCode.exceededWorkLimit.rawValue, -5)
        XCTAssertEqual(OperationResultCode.tooManySponsoring.rawValue, -6)
    }

    func testOperationResultXDRInnerRoundTrip() throws {
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
        let successResult = ManageOfferSuccessResultXDR(offersClaimed: [], offer: .created(offerEntry))
        let claimableBalanceId = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let invokeHash = WrappedData32(Data(repeating: 0xCD, count: 32))

        let cases: [(OperationResultXDR, String)] = [
            (.createAccount(0, CreateAccountResultXDR.success), "createAccount"),
            (.payment(0, PaymentResultXDR.success), "payment"),
            (.pathPayment(0, PathPaymentResultXDR.malformed), "pathPayment"),
            (.changeTrust(0, ChangeTrustResultXDR.success), "changeTrust"),
            (.setOptions(0, SetOptionsResultXDR.success), "setOptions"),
            (.manageSellOffer(0, ManageOfferResultXDR.success(0, successResult)), "manageSellOffer"),
            (.createPassiveSellOffer(0, ManageOfferResultXDR.success(0, successResult)), "createPassiveSellOffer"),
            (.manageBuyOffer(0, ManageOfferResultXDR.success(0, successResult)), "manageBuyOffer"),
            (.allowTrust(0, AllowTrustResultXDR.success), "allowTrust"),
            (.accountMerge(0, AccountMergeResultXDR.sourceAccountBalance(1000000)), "accountMerge"),
            (.inflation(0, InflationResultXDR.notTime), "inflation"),
            (.manageData(0, ManageDataResultXDR.success), "manageData"),
            (.bumpSequence(0, BumpSequenceResultXDR.success), "bumpSequence"),
            (.pathPaymentStrictSend(0, PathPaymentResultXDR.malformed), "pathPaymentStrictSend"),
            (.createClaimableBalance(0, CreateClaimableBalanceResultXDR.balanceID(claimableBalanceId)), "createClaimableBalance"),
            (.claimClaimableBalance(0, ClaimClaimableBalanceResultXDR.success), "claimClaimableBalance"),
            (.beginSponsoringFutureReserves(0, BeginSponsoringFutureReservesResultXDR.success), "beginSponsoringFutureReserves"),
            (.endSponsoringFutureReserves(0, EndSponsoringFutureReservesResultXDR.success), "endSponsoringFutureReserves"),
            (.revokeSponsorship(0, RevokeSponsorshipResultXDR.success), "revokeSponsorship"),
            (.clawback(0, ClawbackResultXDR.success), "clawback"),
            (.clawbackClaimableBalance(0, ClawbackClaimableBalanceResultXDR.success), "clawbackClaimableBalance"),
            (.setTrustLineFlags(0, SetTrustLineFlagsResultXDR.success), "setTrustLineFlags"),
            (.liquidityPoolDeposit(0, LiquidityPoolDepositResultXDR.success), "liquidityPoolDeposit"),
            (.liquidityPoolWithdraw(0, LiquidityPoolWithdrawResultXDR.success), "liquidityPoolWithdraw"),
            (.invokeHostFunction(0, InvokeHostFunctionResultXDR.success(invokeHash)), "invokeHostFunction"),
            (.extendFootprintTTL(0, ExtendFootprintTTLResultXDR.success), "extendFootprintTTL"),
            (.restoreFootprint(0, RestoreFootprintResultXDR.success), "restoreFootprint"),
        ]

        for (result, name) in cases {
            let encoded = try XDREncoder.encode(result)
            XCTAssertFalse(encoded.isEmpty, "Encoding failed for \(name)")

            let decoded = try XDRDecoder.decode(OperationResultXDR.self, data: encoded)

            switch (result, decoded) {
            case (.createAccount, .createAccount),
                 (.payment, .payment),
                 (.pathPayment, .pathPayment),
                 (.changeTrust, .changeTrust),
                 (.setOptions, .setOptions),
                 (.manageSellOffer, .manageSellOffer),
                 (.createPassiveSellOffer, .createPassiveSellOffer),
                 (.manageBuyOffer, .manageBuyOffer),
                 (.allowTrust, .allowTrust),
                 (.accountMerge, .accountMerge),
                 (.inflation, .inflation),
                 (.manageData, .manageData),
                 (.bumpSequence, .bumpSequence),
                 (.pathPaymentStrictSend, .pathPaymentStrictSend),
                 (.createClaimableBalance, .createClaimableBalance),
                 (.claimClaimableBalance, .claimClaimableBalance),
                 (.beginSponsoringFutureReserves, .beginSponsoringFutureReserves),
                 (.endSponsoringFutureReserves, .endSponsoringFutureReserves),
                 (.revokeSponsorship, .revokeSponsorship),
                 (.clawback, .clawback),
                 (.clawbackClaimableBalance, .clawbackClaimableBalance),
                 (.setTrustLineFlags, .setTrustLineFlags),
                 (.liquidityPoolDeposit, .liquidityPoolDeposit),
                 (.liquidityPoolWithdraw, .liquidityPoolWithdraw),
                 (.invokeHostFunction, .invokeHostFunction),
                 (.extendFootprintTTL, .extendFootprintTTL),
                 (.restoreFootprint, .restoreFootprint):
                break // Round-trip matched
            default:
                XCTFail("Round-trip mismatch for \(name)")
            }
        }
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
