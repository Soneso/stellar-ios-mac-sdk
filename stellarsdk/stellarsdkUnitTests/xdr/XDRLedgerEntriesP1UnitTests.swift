//
//  XDRLedgerEntriesP1UnitTests.swift
//  stellarsdkTests
//
//  Tests for types from the first half of Stellar-ledger-entries.x:
//  account entries through liquidity pool entries, contract data/code, TTL.
//

import XCTest
import stellarsdk

class XDRLedgerEntriesP1UnitTests: XCTestCase {

    // MARK: - Simple Enum Round-Trip Tests

    func testAccountFlagsRoundTrip() throws {
        for flag in [AccountFlags.requiredFlag, .revocableFlag, .immutableFlag, .clawbackEnabledFlag] {
            let encoded = try XDREncoder.encode(flag)
            let decoded = try XDRDecoder.decode(AccountFlags.self, data: encoded)
            XCTAssertEqual(decoded, flag)
        }
    }

    func testAccountFlagsRawValues() {
        XCTAssertEqual(AccountFlags.requiredFlag.rawValue, 1)
        XCTAssertEqual(AccountFlags.revocableFlag.rawValue, 2)
        XCTAssertEqual(AccountFlags.immutableFlag.rawValue, 4)
        XCTAssertEqual(AccountFlags.clawbackEnabledFlag.rawValue, 8)
    }

    func testTrustLineFlagsRoundTrip() throws {
        for flag in [TrustLineFlags.authorizedFlag, .authorizedToMaintainLiabilitiesFlag, .trustlineClawbackEnabledFlag] {
            let encoded = try XDREncoder.encode(flag)
            let decoded = try XDRDecoder.decode(TrustLineFlags.self, data: encoded)
            XCTAssertEqual(decoded, flag)
        }
    }

    func testTrustLineFlagsRawValues() {
        XCTAssertEqual(TrustLineFlags.authorizedFlag.rawValue, 1)
        XCTAssertEqual(TrustLineFlags.authorizedToMaintainLiabilitiesFlag.rawValue, 2)
        XCTAssertEqual(TrustLineFlags.trustlineClawbackEnabledFlag.rawValue, 4)
    }

    func testOfferEntryFlagsXDRRoundTrip() throws {
        let flag = OfferEntryFlagsXDR.passiveFlag
        let encoded = try XDREncoder.encode(flag)
        let decoded = try XDRDecoder.decode(OfferEntryFlagsXDR.self, data: encoded)
        XCTAssertEqual(decoded, flag)
        XCTAssertEqual(OfferEntryFlagsXDR.passiveFlag.rawValue, 1)
    }

    func testClaimableBalanceFlagsRoundTrip() throws {
        let flag = ClaimableBalanceFlags.claimableBalanceClawbackEnabledFlag
        let encoded = try XDREncoder.encode(flag)
        let decoded = try XDRDecoder.decode(ClaimableBalanceFlags.self, data: encoded)
        XCTAssertEqual(decoded, flag)
        XCTAssertEqual(ClaimableBalanceFlags.claimableBalanceClawbackEnabledFlag.rawValue, 1)
    }

    func testClaimPredicateTypeRoundTrip() throws {
        let allCases: [ClaimPredicateType] = [
            .claimPredicateUnconditional,
            .claimPredicateAnd,
            .claimPredicateOr,
            .claimPredicateNot,
            .claimPredicateBeforeAbsTime,
            .claimPredicateBeforeRelTime
        ]
        for pt in allCases {
            let encoded = try XDREncoder.encode(pt)
            let decoded = try XDRDecoder.decode(ClaimPredicateType.self, data: encoded)
            XCTAssertEqual(decoded, pt)
        }
    }

    func testClaimPredicateTypeRawValues() {
        XCTAssertEqual(ClaimPredicateType.claimPredicateUnconditional.rawValue, 0)
        XCTAssertEqual(ClaimPredicateType.claimPredicateAnd.rawValue, 1)
        XCTAssertEqual(ClaimPredicateType.claimPredicateOr.rawValue, 2)
        XCTAssertEqual(ClaimPredicateType.claimPredicateNot.rawValue, 3)
        XCTAssertEqual(ClaimPredicateType.claimPredicateBeforeAbsTime.rawValue, 4)
        XCTAssertEqual(ClaimPredicateType.claimPredicateBeforeRelTime.rawValue, 5)
    }

    func testClaimantTypeRoundTrip() throws {
        let ct = ClaimantType.claimantTypeV0
        let encoded = try XDREncoder.encode(ct)
        let decoded = try XDRDecoder.decode(ClaimantType.self, data: encoded)
        XCTAssertEqual(decoded, ct)
        XCTAssertEqual(ClaimantType.claimantTypeV0.rawValue, 0)
    }

    func testClaimableBalanceIDTypeRoundTrip() throws {
        let t = ClaimableBalanceIDType.claimableBalanceIDTypeV0
        let encoded = try XDREncoder.encode(t)
        let decoded = try XDRDecoder.decode(ClaimableBalanceIDType.self, data: encoded)
        XCTAssertEqual(decoded, t)
        XCTAssertEqual(ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue, 0)
    }

    func testLiquidityPoolTypeRoundTrip() throws {
        let t = LiquidityPoolType.constantProduct
        let encoded = try XDREncoder.encode(t)
        let decoded = try XDRDecoder.decode(LiquidityPoolType.self, data: encoded)
        XCTAssertEqual(decoded, t)
        XCTAssertEqual(LiquidityPoolType.constantProduct.rawValue, 0)
    }

    func testContractDataDurabilityRoundTrip() throws {
        for dur in [ContractDataDurability.temporary, .persistent] {
            let encoded = try XDREncoder.encode(dur)
            let decoded = try XDRDecoder.decode(ContractDataDurability.self, data: encoded)
            XCTAssertEqual(decoded, dur)
        }
        XCTAssertEqual(ContractDataDurability.temporary.rawValue, 0)
        XCTAssertEqual(ContractDataDurability.persistent.rawValue, 1)
    }

    // MARK: - LiabilitiesXDR Tests

    func testLiabilitiesXDRRoundTrip() throws {
        let original = LiabilitiesXDR(buying: 500_000_000, selling: 300_000_000)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LiabilitiesXDR.self, data: encoded)
        XCTAssertEqual(decoded.buying, 500_000_000)
        XCTAssertEqual(decoded.selling, 300_000_000)
    }

    func testLiabilitiesXDRZeroValues() throws {
        let original = LiabilitiesXDR(buying: 0, selling: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LiabilitiesXDR.self, data: encoded)
        XCTAssertEqual(decoded.buying, 0)
        XCTAssertEqual(decoded.selling, 0)
    }

    func testLiabilitiesXDRLargeValues() throws {
        let original = LiabilitiesXDR(buying: Int64.max, selling: Int64.max - 1)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LiabilitiesXDR.self, data: encoded)
        XCTAssertEqual(decoded.buying, Int64.max)
        XCTAssertEqual(decoded.selling, Int64.max - 1)
    }

    // MARK: - AccountEntryExtensionV3 Tests

    func testAccountEntryExtensionV3RoundTrip() throws {
        let original = AccountEntryExtensionV3(
            ext: .void,
            seqLedger: 98765,
            seqTime: 1700000000
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryExtensionV3.self, data: encoded)
        XCTAssertEqual(decoded.seqLedger, 98765)
        XCTAssertEqual(decoded.seqTime, 1700000000)
    }

    func testAccountEntryExtensionV3MaxValues() throws {
        let original = AccountEntryExtensionV3(
            ext: .void,
            seqLedger: UInt32.max,
            seqTime: UInt64.max
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryExtensionV3.self, data: encoded)
        XCTAssertEqual(decoded.seqLedger, UInt32.max)
        XCTAssertEqual(decoded.seqTime, UInt64.max)
    }

    // MARK: - AccountEntryExtV2XDR Union Tests

    func testAccountEntryExtV2XDRVoid() throws {
        let original = AccountEntryExtV2XDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryExtV2XDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 0)
        if case .void = decoded {
            // expected
        } else {
            XCTFail("Expected .void")
        }
    }

    func testAccountEntryExtV2XDRWithV3() throws {
        let v3 = AccountEntryExtensionV3(ext: .void, seqLedger: 42, seqTime: 12345)
        let original = AccountEntryExtV2XDR.accountEntryExtensionV3(v3)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryExtV2XDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 3)
        if case .accountEntryExtensionV3(let decodedV3) = decoded {
            XCTAssertEqual(decodedV3.seqLedger, 42)
            XCTAssertEqual(decodedV3.seqTime, 12345)
        } else {
            XCTFail("Expected .accountEntryExtensionV3")
        }
    }

    // MARK: - AccountEntryExtensionV2 Tests

    func testAccountEntryExtensionV2EmptySponsors() throws {
        let original = AccountEntryExtensionV2(
            numSponsored: 0,
            numSponsoring: 0,
            signerSponsoringIDs: [],
            reserved: .void
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryExtensionV2.self, data: encoded)
        XCTAssertEqual(decoded.numSponsored, 0)
        XCTAssertEqual(decoded.numSponsoring, 0)
        XCTAssertEqual(decoded.signerSponsoringIDs.count, 0)
    }

    func testAccountEntryExtensionV2WithSponsorsAndV3() throws {
        let pk = try XDRTestHelpers.publicKey()
        let v3 = AccountEntryExtensionV3(ext: .void, seqLedger: 100, seqTime: 200)
        let original = AccountEntryExtensionV2(
            numSponsored: 5,
            numSponsoring: 3,
            signerSponsoringIDs: [pk, nil, pk],
            reserved: .accountEntryExtensionV3(v3)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryExtensionV2.self, data: encoded)
        XCTAssertEqual(decoded.numSponsored, 5)
        XCTAssertEqual(decoded.numSponsoring, 3)
        XCTAssertEqual(decoded.signerSponsoringIDs.count, 3)
        XCTAssertNotNil(decoded.signerSponsoringIDs[0])
        XCTAssertNil(decoded.signerSponsoringIDs[1])
        XCTAssertNotNil(decoded.signerSponsoringIDs[2])
        if case .accountEntryExtensionV3(let dV3) = decoded.reserved {
            XCTAssertEqual(dV3.seqLedger, 100)
            XCTAssertEqual(dV3.seqTime, 200)
        } else {
            XCTFail("Expected .accountEntryExtensionV3")
        }
    }

    // MARK: - AccountEntryExtV1XDR Union Tests

    func testAccountEntryExtV1XDRVoid() throws {
        let original = AccountEntryExtV1XDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryExtV1XDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 0)
        if case .void = decoded {
            // expected
        } else {
            XCTFail("Expected .void")
        }
    }

    func testAccountEntryExtV1XDRWithV2() throws {
        let pk = try XDRTestHelpers.publicKey()
        let v2 = AccountEntryExtensionV2(
            numSponsored: 1,
            numSponsoring: 2,
            signerSponsoringIDs: [pk],
            reserved: .void
        )
        let original = AccountEntryExtV1XDR.accountEntryExtensionV2(v2)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryExtV1XDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 2)
        if case .accountEntryExtensionV2(let dV2) = decoded {
            XCTAssertEqual(dV2.numSponsored, 1)
            XCTAssertEqual(dV2.numSponsoring, 2)
            XCTAssertEqual(dV2.signerSponsoringIDs.count, 1)
        } else {
            XCTFail("Expected .accountEntryExtensionV2")
        }
    }

    // MARK: - AccountEntryExtensionV1 Tests

    func testAccountEntryExtensionV1WithVoidExt() throws {
        let liabilities = LiabilitiesXDR(buying: 100_000, selling: 50_000)
        let original = AccountEntryExtensionV1(liabilities: liabilities, reserved: .void)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryExtensionV1.self, data: encoded)
        XCTAssertEqual(decoded.liabilities.buying, 100_000)
        XCTAssertEqual(decoded.liabilities.selling, 50_000)
    }

    func testAccountEntryExtensionV1WithV2Ext() throws {
        let liabilities = LiabilitiesXDR(buying: 250_000, selling: 125_000)
        let v2 = AccountEntryExtensionV2(
            numSponsored: 2,
            numSponsoring: 1,
            signerSponsoringIDs: [],
            reserved: .void
        )
        let original = AccountEntryExtensionV1(liabilities: liabilities, reserved: .accountEntryExtensionV2(v2))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryExtensionV1.self, data: encoded)
        XCTAssertEqual(decoded.liabilities.buying, 250_000)
        XCTAssertEqual(decoded.liabilities.selling, 125_000)
        if case .accountEntryExtensionV2(let dV2) = decoded.reserved {
            XCTAssertEqual(dV2.numSponsored, 2)
        } else {
            XCTFail("Expected .accountEntryExtensionV2 in ext")
        }
    }

    // MARK: - AccountEntryExtXDR Union Tests

    func testAccountEntryExtXDRVoid() throws {
        let original = AccountEntryExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryExtXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 0)
        if case .void = decoded {
            // expected
        } else {
            XCTFail("Expected .void")
        }
    }

    func testAccountEntryExtXDRWithV1() throws {
        let liabilities = LiabilitiesXDR(buying: 10, selling: 20)
        let v1 = AccountEntryExtensionV1(liabilities: liabilities, reserved: .void)
        let original = AccountEntryExtXDR.accountEntryExtensionV1(v1)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryExtXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 1)
        if case .accountEntryExtensionV1(let dV1) = decoded {
            XCTAssertEqual(dV1.liabilities.buying, 10)
            XCTAssertEqual(dV1.liabilities.selling, 20)
        } else {
            XCTFail("Expected .accountEntryExtensionV1")
        }
    }

    // MARK: - AccountEntryXDR Tests

    func testAccountEntryXDRMinimal() throws {
        let pk = try XDRTestHelpers.publicKey()
        let thresholds = XDRTestHelpers.wrappedData4()
        let original = AccountEntryXDR(
            accountID: pk,
            balance: 100_000_000,
            sequenceNumber: 42,
            numSubEntries: 3,
            flags: 0,
            homeDomain: "",
            thresholds: thresholds,
            signers: [],
            ext: .void
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.balance, 100_000_000)
        XCTAssertEqual(decoded.sequenceNumber, 42)
        XCTAssertEqual(decoded.numSubEntries, 3)
        XCTAssertNil(decoded.inflationDest)
        XCTAssertEqual(decoded.flags, 0)
        XCTAssertEqual(decoded.homeDomain, "")
        XCTAssertEqual(decoded.signers.count, 0)
    }

    func testAccountEntryXDRWithInflationDestAndSigners() throws {
        let pk = try XDRTestHelpers.publicKey()
        let thresholds = XDRTestHelpers.wrappedData4()
        let signer = SignerXDR(
            key: .ed25519(XDRTestHelpers.wrappedData32()),
            weight: 10
        )
        let original = AccountEntryXDR(
            accountID: pk,
            balance: 50_000_000,
            sequenceNumber: 100,
            numSubEntries: 1,
            inflationDest: pk,
            flags: 3, // required + revocable
            homeDomain: "example.com",
            thresholds: thresholds,
            signers: [signer],
            ext: .void
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.balance, 50_000_000)
        XCTAssertEqual(decoded.sequenceNumber, 100)
        XCTAssertNotNil(decoded.inflationDest)
        XCTAssertEqual(decoded.flags, 3)
        XCTAssertEqual(decoded.homeDomain, "example.com")
        XCTAssertEqual(decoded.signers.count, 1)
        XCTAssertEqual(decoded.signers[0].weight, 10)
    }

    func testAccountEntryXDRWithFullExtensionChain() throws {
        let pk = try XDRTestHelpers.publicKey()
        let thresholds = XDRTestHelpers.wrappedData4()
        let v3 = AccountEntryExtensionV3(ext: .void, seqLedger: 500, seqTime: 1700000000)
        let v2 = AccountEntryExtensionV2(
            numSponsored: 2,
            numSponsoring: 1,
            signerSponsoringIDs: [pk, nil],
            reserved: .accountEntryExtensionV3(v3)
        )
        let v1 = AccountEntryExtensionV1(
            liabilities: LiabilitiesXDR(buying: 1000, selling: 2000),
            reserved: .accountEntryExtensionV2(v2)
        )
        let original = AccountEntryXDR(
            accountID: pk,
            balance: 200_000_000,
            sequenceNumber: 999,
            numSubEntries: 10,
            flags: 15, // all flags
            homeDomain: "stellar.org",
            thresholds: thresholds,
            signers: [],
            ext: .accountEntryExtensionV1(v1)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AccountEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.balance, 200_000_000)
        XCTAssertEqual(decoded.sequenceNumber, 999)
        XCTAssertEqual(decoded.flags, 15)
        XCTAssertEqual(decoded.homeDomain, "stellar.org")
        // Walk the extension chain
        if case .accountEntryExtensionV1(let dV1) = decoded.ext {
            XCTAssertEqual(dV1.liabilities.buying, 1000)
            XCTAssertEqual(dV1.liabilities.selling, 2000)
            if case .accountEntryExtensionV2(let dV2) = dV1.reserved {
                XCTAssertEqual(dV2.numSponsored, 2)
                XCTAssertEqual(dV2.numSponsoring, 1)
                XCTAssertEqual(dV2.signerSponsoringIDs.count, 2)
                if case .accountEntryExtensionV3(let dV3) = dV2.reserved {
                    XCTAssertEqual(dV3.seqLedger, 500)
                    XCTAssertEqual(dV3.seqTime, 1700000000)
                } else {
                    XCTFail("Expected V3 extension")
                }
            } else {
                XCTFail("Expected V2 extension")
            }
        } else {
            XCTFail("Expected V1 extension")
        }
    }

    // MARK: - TrustlineEntryExtensionV2 Tests

    func testTrustlineEntryExtensionV2RoundTrip() throws {
        let original = TrustlineEntryExtensionV2(liquidityPoolUseCount: 7)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TrustlineEntryExtensionV2.self, data: encoded)
        XCTAssertEqual(decoded.liquidityPoolUseCount, 7)
        XCTAssertEqual(decoded.ext, 0)
    }

    func testTrustlineEntryExtensionV2ZeroCount() throws {
        let original = TrustlineEntryExtensionV2(liquidityPoolUseCount: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TrustlineEntryExtensionV2.self, data: encoded)
        XCTAssertEqual(decoded.liquidityPoolUseCount, 0)
    }

    // MARK: - OfferEntryXDR Tests

    func testOfferEntryXDRWithNonNativeAssets() throws {
        let pk = try XDRTestHelpers.publicKey()
        let assetCode4 = WrappedData4(Data([0x55, 0x53, 0x44, 0x00])) // "USD\0"
        let alphaNum4 = Alpha4XDR(assetCode: assetCode4, issuer: pk)
        let selling = AssetXDR.alphanum4(alphaNum4)

        let offer = OfferEntryXDR(
            sellerID: pk,
            offerID: 77777,
            selling: selling,
            buying: .native,
            amount: 50_000_000,
            price: PriceXDR(n: 3, d: 1),
            flags: 1 // passive
        )
        let encoded = try XDREncoder.encode(offer)
        let decoded = try XDRDecoder.decode(OfferEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.offerID, 77777)
        XCTAssertEqual(decoded.amount, 50_000_000)
        XCTAssertEqual(decoded.price.n, 3)
        XCTAssertEqual(decoded.price.d, 1)
        XCTAssertEqual(decoded.flags, 1)
        XCTAssertEqual(decoded.reserved, 0)
    }

    func testOfferEntryXDRLargeOfferID() throws {
        let pk = try XDRTestHelpers.publicKey()
        let offer = OfferEntryXDR(
            sellerID: pk,
            offerID: UInt64.max,
            selling: .native,
            buying: .native,
            amount: 1,
            price: PriceXDR(n: 1, d: 1),
            flags: 0
        )
        let encoded = try XDREncoder.encode(offer)
        let decoded = try XDRDecoder.decode(OfferEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.offerID, UInt64.max)
    }

    // MARK: - OfferEntryXDRExtXDR Tests

    func testOfferEntryXDRExtXDRVoid() throws {
        let original = OfferEntryXDRExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(OfferEntryXDRExtXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 0)
        if case .void = decoded {
            // expected
        } else {
            XCTFail("Expected .void")
        }
    }

    // MARK: - DataEntryXDR Tests

    func testDataEntryXDRRoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = DataEntryXDR(
            accountID: pk,
            dataName: "myKey",
            dataValue: Data([0x01, 0x02, 0x03, 0x04])
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(DataEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.dataName, "myKey")
        XCTAssertEqual(decoded.dataValue, Data([0x01, 0x02, 0x03, 0x04]))
        XCTAssertEqual(decoded.reserved, 0)
    }

    func testDataEntryXDRMaxLengthName() throws {
        let pk = try XDRTestHelpers.publicKey()
        let longName = String(repeating: "x", count: 32) // string32 max
        let original = DataEntryXDR(
            accountID: pk,
            dataName: longName,
            dataValue: Data(repeating: 0xAA, count: 64) // DataValue max 64 bytes
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(DataEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.dataName, longName)
        XCTAssertEqual(decoded.dataValue.count, 64)
    }

    func testDataEntryXDREmptyData() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = DataEntryXDR(
            accountID: pk,
            dataName: "empty",
            dataValue: Data()
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(DataEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.dataName, "empty")
        XCTAssertEqual(decoded.dataValue.count, 0)
    }

    // MARK: - DataEntryXDRExtXDR Tests

    func testDataEntryXDRExtXDRVoid() throws {
        let original = DataEntryXDRExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(DataEntryXDRExtXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 0)
        if case .void = decoded {
            // expected
        } else {
            XCTFail("Expected .void")
        }
    }

    // MARK: - ClaimPredicateXDR Tests (depth 0, 1, 2)

    func testClaimPredicateXDRUnconditional() throws {
        let original = ClaimPredicateXDR.claimPredicateUnconditional
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimPredicateXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ClaimPredicateType.claimPredicateUnconditional.rawValue)
        if case .claimPredicateUnconditional = decoded {
            // expected
        } else {
            XCTFail("Expected .claimPredicateUnconditional")
        }
    }

    func testClaimPredicateXDRBeforeAbsTime() throws {
        let original = ClaimPredicateXDR.claimPredicateBeforeAbsTime(1704067200)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimPredicateXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ClaimPredicateType.claimPredicateBeforeAbsTime.rawValue)
        if case .claimPredicateBeforeAbsTime(let t) = decoded {
            XCTAssertEqual(t, 1704067200)
        } else {
            XCTFail("Expected .claimPredicateBeforeAbsTime")
        }
    }

    func testClaimPredicateXDRBeforeRelTime() throws {
        let original = ClaimPredicateXDR.claimPredicateBeforeRelTime(604800) // 7 days
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimPredicateXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ClaimPredicateType.claimPredicateBeforeRelTime.rawValue)
        if case .claimPredicateBeforeRelTime(let t) = decoded {
            XCTAssertEqual(t, 604800)
        } else {
            XCTFail("Expected .claimPredicateBeforeRelTime")
        }
    }

    func testClaimPredicateXDRNotWithSome() throws {
        let inner = ClaimPredicateXDR.claimPredicateBeforeAbsTime(999999)
        let original = ClaimPredicateXDR.claimPredicateNot(inner)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimPredicateXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ClaimPredicateType.claimPredicateNot.rawValue)
        if case .claimPredicateNot(let innerDecoded) = decoded {
            XCTAssertNotNil(innerDecoded)
            if case .claimPredicateBeforeAbsTime(let t) = innerDecoded! {
                XCTAssertEqual(t, 999999)
            } else {
                XCTFail("Expected .claimPredicateBeforeAbsTime inside NOT")
            }
        } else {
            XCTFail("Expected .claimPredicateNot")
        }
    }

    func testClaimPredicateXDRNotWithNil() throws {
        let original = ClaimPredicateXDR.claimPredicateNot(nil)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimPredicateXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ClaimPredicateType.claimPredicateNot.rawValue)
        if case .claimPredicateNot(let inner) = decoded {
            XCTAssertNil(inner)
        } else {
            XCTFail("Expected .claimPredicateNot(nil)")
        }
    }

    func testClaimPredicateXDRAndDepth1() throws {
        let pred1 = ClaimPredicateXDR.claimPredicateBeforeAbsTime(1704067200)
        let pred2 = ClaimPredicateXDR.claimPredicateBeforeRelTime(86400)
        let original = ClaimPredicateXDR.claimPredicateAnd([pred1, pred2])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimPredicateXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ClaimPredicateType.claimPredicateAnd.rawValue)
        if case .claimPredicateAnd(let preds) = decoded {
            XCTAssertEqual(preds.count, 2)
            if case .claimPredicateBeforeAbsTime(let t) = preds[0] {
                XCTAssertEqual(t, 1704067200)
            } else {
                XCTFail("Expected abs time in AND[0]")
            }
            if case .claimPredicateBeforeRelTime(let t) = preds[1] {
                XCTAssertEqual(t, 86400)
            } else {
                XCTFail("Expected rel time in AND[1]")
            }
        } else {
            XCTFail("Expected .claimPredicateAnd")
        }
    }

    func testClaimPredicateXDROrDepth1() throws {
        let pred1 = ClaimPredicateXDR.claimPredicateUnconditional
        let pred2 = ClaimPredicateXDR.claimPredicateBeforeAbsTime(5000)
        let original = ClaimPredicateXDR.claimPredicateOr([pred1, pred2])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimPredicateXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ClaimPredicateType.claimPredicateOr.rawValue)
        if case .claimPredicateOr(let preds) = decoded {
            XCTAssertEqual(preds.count, 2)
            if case .claimPredicateUnconditional = preds[0] {
                // expected
            } else {
                XCTFail("Expected unconditional in OR[0]")
            }
            if case .claimPredicateBeforeAbsTime(let t) = preds[1] {
                XCTAssertEqual(t, 5000)
            } else {
                XCTFail("Expected abs time in OR[1]")
            }
        } else {
            XCTFail("Expected .claimPredicateOr")
        }
    }

    func testClaimPredicateXDRNestedDepth2() throws {
        // AND(OR(absTime, relTime), NOT(unconditional))
        let abs = ClaimPredicateXDR.claimPredicateBeforeAbsTime(1000)
        let rel = ClaimPredicateXDR.claimPredicateBeforeRelTime(2000)
        let orPred = ClaimPredicateXDR.claimPredicateOr([abs, rel])
        let notPred = ClaimPredicateXDR.claimPredicateNot(.claimPredicateUnconditional)
        let original = ClaimPredicateXDR.claimPredicateAnd([orPred, notPred])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimPredicateXDR.self, data: encoded)

        if case .claimPredicateAnd(let andPreds) = decoded {
            XCTAssertEqual(andPreds.count, 2)

            // First element: OR
            if case .claimPredicateOr(let orPreds) = andPreds[0] {
                XCTAssertEqual(orPreds.count, 2)
                if case .claimPredicateBeforeAbsTime(let t) = orPreds[0] {
                    XCTAssertEqual(t, 1000)
                } else {
                    XCTFail("Expected abs time in OR[0]")
                }
                if case .claimPredicateBeforeRelTime(let t) = orPreds[1] {
                    XCTAssertEqual(t, 2000)
                } else {
                    XCTFail("Expected rel time in OR[1]")
                }
            } else {
                XCTFail("Expected .claimPredicateOr in AND[0]")
            }

            // Second element: NOT
            if case .claimPredicateNot(let notInner) = andPreds[1] {
                XCTAssertNotNil(notInner)
                if case .claimPredicateUnconditional = notInner! {
                    // expected
                } else {
                    XCTFail("Expected unconditional inside NOT")
                }
            } else {
                XCTFail("Expected .claimPredicateNot in AND[1]")
            }
        } else {
            XCTFail("Expected .claimPredicateAnd at top level")
        }
    }

    // MARK: - ClaimantV0XDR Tests

    func testClaimantV0XDRRoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let pred = ClaimPredicateXDR.claimPredicateBeforeAbsTime(1704067200)
        let original = ClaimantV0XDR(accountID: pk, predicate: pred)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimantV0XDR.self, data: encoded)
        XCTAssertEqual(decoded.accountID.accountId, pk.accountId)
        if case .claimPredicateBeforeAbsTime(let t) = decoded.predicate {
            XCTAssertEqual(t, 1704067200)
        } else {
            XCTFail("Expected .claimPredicateBeforeAbsTime")
        }
    }

    // MARK: - ClaimantXDR Union Tests

    func testClaimantXDRV0RoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let v0 = ClaimantV0XDR(accountID: pk, predicate: .claimPredicateUnconditional)
        let original = ClaimantXDR.claimantTypeV0(v0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimantXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ClaimantType.claimantTypeV0.rawValue)
        if case .claimantTypeV0(let dV0) = decoded {
            XCTAssertEqual(dV0.accountID.accountId, pk.accountId)
            if case .claimPredicateUnconditional = dV0.predicate {
                // expected
            } else {
                XCTFail("Expected unconditional predicate")
            }
        } else {
            XCTFail("Expected .claimantTypeV0")
        }
    }

    // MARK: - ClaimableBalanceIDXDR Union Tests

    func testClaimableBalanceIDXDRRoundTrip() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let original = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(hash)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimableBalanceIDXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)
        if case .claimableBalanceIDTypeV0(let dHash) = decoded {
            XCTAssertEqual(dHash.wrapped, hash.wrapped)
        } else {
            XCTFail("Expected .claimableBalanceIDTypeV0")
        }
    }

    // MARK: - ClaimableBalanceEntryExtensionV1ExtXDR Tests

    func testClaimableBalanceEntryExtensionV1ExtXDRVoid() throws {
        let original = ClaimableBalanceEntryExtensionV1ExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimableBalanceEntryExtensionV1ExtXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 0)
    }

    // MARK: - ClaimableBalanceEntryExtensionV1 Tests

    func testClaimableBalanceEntryExtensionV1RoundTrip() throws {
        let original = ClaimableBalanceEntryExtensionV1(flags: 1)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimableBalanceEntryExtensionV1.self, data: encoded)
        XCTAssertEqual(decoded.flags, 1)
        XCTAssertEqual(decoded.reserved, 0)
    }

    func testClaimableBalanceEntryExtensionV1ZeroFlags() throws {
        let original = ClaimableBalanceEntryExtensionV1(flags: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimableBalanceEntryExtensionV1.self, data: encoded)
        XCTAssertEqual(decoded.flags, 0)
    }

    // MARK: - ClaimableBalanceEntryExtXDR Union Tests

    func testClaimableBalanceEntryExtXDRVoid() throws {
        let original = ClaimableBalanceEntryExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimableBalanceEntryExtXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 0)
        if case .void = decoded {
            // expected
        } else {
            XCTFail("Expected .void")
        }
    }

    func testClaimableBalanceEntryExtXDRWithV1() throws {
        let v1 = ClaimableBalanceEntryExtensionV1(flags: 1)
        let original = ClaimableBalanceEntryExtXDR.claimableBalanceEntryExtensionV1(v1)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimableBalanceEntryExtXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 1)
        if case .claimableBalanceEntryExtensionV1(let dV1) = decoded {
            XCTAssertEqual(dV1.flags, 1)
        } else {
            XCTFail("Expected .claimableBalanceEntryExtensionV1")
        }
    }

    // MARK: - ClaimableBalanceEntryXDR Tests

    func testClaimableBalanceEntryXDRMinimal() throws {
        let pk = try XDRTestHelpers.publicKey()
        let balanceID = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(XDRTestHelpers.wrappedData32())
        let claimant = ClaimantXDR.claimantTypeV0(
            ClaimantV0XDR(accountID: pk, predicate: .claimPredicateUnconditional)
        )
        let original = ClaimableBalanceEntryXDR(
            claimableBalanceID: balanceID,
            claimants: [claimant],
            asset: .native,
            amount: 100_000_000,
            ext: .void
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimableBalanceEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.amount, 100_000_000)
        XCTAssertEqual(decoded.claimants.count, 1)
        XCTAssertEqual(decoded.ext.type(), 0)
    }

    func testClaimableBalanceEntryXDRWithV1ExtAndMultipleClaimants() throws {
        let pk = try XDRTestHelpers.publicKey()
        let balanceID = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(XDRTestHelpers.wrappedData32())
        let claimant1 = ClaimantXDR.claimantTypeV0(
            ClaimantV0XDR(accountID: pk, predicate: .claimPredicateUnconditional)
        )
        let claimant2 = ClaimantXDR.claimantTypeV0(
            ClaimantV0XDR(accountID: pk, predicate: .claimPredicateBeforeRelTime(3600))
        )
        let v1Ext = ClaimableBalanceEntryExtensionV1(flags: 1)
        let original = ClaimableBalanceEntryXDR(
            claimableBalanceID: balanceID,
            claimants: [claimant1, claimant2],
            asset: .native,
            amount: 500_000_000,
            ext: .claimableBalanceEntryExtensionV1(v1Ext)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimableBalanceEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.amount, 500_000_000)
        XCTAssertEqual(decoded.claimants.count, 2)
        if case .claimableBalanceEntryExtensionV1(let dV1) = decoded.ext {
            XCTAssertEqual(dV1.flags, 1)
        } else {
            XCTFail("Expected v1 extension")
        }
        // Verify second claimant predicate
        if case .claimantTypeV0(let dV0) = decoded.claimants[1] {
            if case .claimPredicateBeforeRelTime(let t) = dV0.predicate {
                XCTAssertEqual(t, 3600)
            } else {
                XCTFail("Expected rel time predicate")
            }
        } else {
            XCTFail("Expected claimantTypeV0")
        }
    }

    // MARK: - LiquidityPoolConstantProductParametersXDR Tests

    func testLiquidityPoolConstantProductParametersXDRRoundTrip() throws {
        let original = LiquidityPoolConstantProductParametersXDR(
            assetA: .native,
            assetB: .native,
            fee: 30
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LiquidityPoolConstantProductParametersXDR.self, data: encoded)
        XCTAssertEqual(decoded.fee, 30)
    }

    func testLiquidityPoolConstantProductParametersXDRWithNonNativeAssets() throws {
        let pk = try XDRTestHelpers.publicKey()
        let assetCode4 = WrappedData4(Data([0x55, 0x53, 0x44, 0x00]))
        let alphaNum4 = Alpha4XDR(assetCode: assetCode4, issuer: pk)
        let original = LiquidityPoolConstantProductParametersXDR(
            assetA: .native,
            assetB: .alphanum4(alphaNum4),
            fee: 30
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LiquidityPoolConstantProductParametersXDR.self, data: encoded)
        XCTAssertEqual(decoded.fee, 30)
    }

    // MARK: - ConstantProductXDR Tests

    func testConstantProductXDRRoundTrip() throws {
        let params = LiquidityPoolConstantProductParametersXDR(
            assetA: .native,
            assetB: .native,
            fee: 30
        )
        let original = ConstantProductXDR(
            params: params,
            reserveA: 1_000_000_000,
            reserveB: 2_000_000_000,
            totalPoolShares: 500_000_000,
            poolSharesTrustLineCount: 42
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConstantProductXDR.self, data: encoded)
        XCTAssertEqual(decoded.reserveA, 1_000_000_000)
        XCTAssertEqual(decoded.reserveB, 2_000_000_000)
        XCTAssertEqual(decoded.totalPoolShares, 500_000_000)
        XCTAssertEqual(decoded.poolSharesTrustLineCount, 42)
        XCTAssertEqual(decoded.params.fee, 30)
    }

    // MARK: - LiquidityPoolBodyXDR Union Tests

    func testLiquidityPoolBodyXDRConstantProduct() throws {
        let params = LiquidityPoolConstantProductParametersXDR(
            assetA: .native,
            assetB: .native,
            fee: 30
        )
        let cp = ConstantProductXDR(
            params: params,
            reserveA: 100,
            reserveB: 200,
            totalPoolShares: 50,
            poolSharesTrustLineCount: 3
        )
        let original = LiquidityPoolBodyXDR.constantProduct(cp)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LiquidityPoolBodyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LiquidityPoolType.constantProduct.rawValue)
        if case .constantProduct(let dCp) = decoded {
            XCTAssertEqual(dCp.reserveA, 100)
            XCTAssertEqual(dCp.reserveB, 200)
            XCTAssertEqual(dCp.totalPoolShares, 50)
            XCTAssertEqual(dCp.poolSharesTrustLineCount, 3)
        } else {
            XCTFail("Expected .constantProduct")
        }
    }

    // MARK: - LiquidityPoolEntryXDR Tests

    func testLiquidityPoolEntryXDRRoundTrip() throws {
        let poolID = XDRTestHelpers.wrappedData32()
        let params = LiquidityPoolConstantProductParametersXDR(
            assetA: .native,
            assetB: .native,
            fee: 30
        )
        let cp = ConstantProductXDR(
            params: params,
            reserveA: 10_000_000,
            reserveB: 20_000_000,
            totalPoolShares: 5_000_000,
            poolSharesTrustLineCount: 100
        )
        let original = LiquidityPoolEntryXDR(
            liquidityPoolID: poolID,
            body: .constantProduct(cp)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LiquidityPoolEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.liquidityPoolID.wrapped, poolID.wrapped)
        if case .constantProduct(let dCp) = decoded.body {
            XCTAssertEqual(dCp.reserveA, 10_000_000)
            XCTAssertEqual(dCp.reserveB, 20_000_000)
            XCTAssertEqual(dCp.totalPoolShares, 5_000_000)
            XCTAssertEqual(dCp.poolSharesTrustLineCount, 100)
            XCTAssertEqual(dCp.params.fee, 30)
        } else {
            XCTFail("Expected .constantProduct body")
        }
    }

    // MARK: - ContractDataEntryXDR Tests

    func testContractDataEntryXDRTemporary() throws {
        let pk = try XDRTestHelpers.publicKey()
        let contract = SCAddressXDR.account(pk)
        let original = ContractDataEntryXDR(
            ext: .void,
            contract: contract,
            key: .u32(42),
            durability: .temporary,
            val: .i64(99)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractDataEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.durability, .temporary)
        if case .u32(let k) = decoded.key {
            XCTAssertEqual(k, 42)
        } else {
            XCTFail("Expected .u32 key")
        }
        if case .i64(let v) = decoded.val {
            XCTAssertEqual(v, 99)
        } else {
            XCTFail("Expected .i64 val")
        }
    }

    func testContractDataEntryXDRPersistent() throws {
        let contractAddr = SCAddressXDR.contract(XDRTestHelpers.wrappedData32())
        let original = ContractDataEntryXDR(
            ext: .void,
            contract: contractAddr,
            key: .symbol("counter"),
            durability: .persistent,
            val: .u128(UInt128PartsXDR(hi: 0, lo: 1000))
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractDataEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.durability, .persistent)
        if case .symbol(let s) = decoded.key {
            XCTAssertEqual(s, "counter")
        } else {
            XCTFail("Expected .symbol key")
        }
    }

    // MARK: - ContractCodeCostInputsXDR Tests

    func testContractCodeCostInputsXDRRoundTrip() throws {
        let original = ContractCodeCostInputsXDR(
            ext: .void,
            nInstructions: 1000,
            nFunctions: 50,
            nGlobals: 10,
            nTableEntries: 5,
            nTypes: 20,
            nDataSegments: 3,
            nElemSegments: 2,
            nImports: 15,
            nExports: 8,
            nDataSegmentBytes: 4096
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCodeCostInputsXDR.self, data: encoded)
        XCTAssertEqual(decoded.nInstructions, 1000)
        XCTAssertEqual(decoded.nFunctions, 50)
        XCTAssertEqual(decoded.nGlobals, 10)
        XCTAssertEqual(decoded.nTableEntries, 5)
        XCTAssertEqual(decoded.nTypes, 20)
        XCTAssertEqual(decoded.nDataSegments, 3)
        XCTAssertEqual(decoded.nElemSegments, 2)
        XCTAssertEqual(decoded.nImports, 15)
        XCTAssertEqual(decoded.nExports, 8)
        XCTAssertEqual(decoded.nDataSegmentBytes, 4096)
    }

    func testContractCodeCostInputsXDRZeroValues() throws {
        let original = ContractCodeCostInputsXDR(
            ext: .void,
            nInstructions: 0,
            nFunctions: 0,
            nGlobals: 0,
            nTableEntries: 0,
            nTypes: 0,
            nDataSegments: 0,
            nElemSegments: 0,
            nImports: 0,
            nExports: 0,
            nDataSegmentBytes: 0
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCodeCostInputsXDR.self, data: encoded)
        XCTAssertEqual(decoded.nInstructions, 0)
        XCTAssertEqual(decoded.nFunctions, 0)
        XCTAssertEqual(decoded.nDataSegmentBytes, 0)
    }

    // MARK: - ContractCodeEntryExtV1 Tests

    func testContractCodeEntryExtV1RoundTrip() throws {
        let costInputs = ContractCodeCostInputsXDR(
            ext: .void,
            nInstructions: 500,
            nFunctions: 25,
            nGlobals: 5,
            nTableEntries: 2,
            nTypes: 10,
            nDataSegments: 1,
            nElemSegments: 0,
            nImports: 8,
            nExports: 3,
            nDataSegmentBytes: 2048
        )
        let original = ContractCodeEntryExtV1(ext: .void, costInputs: costInputs)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCodeEntryExtV1.self, data: encoded)
        XCTAssertEqual(decoded.costInputs.nInstructions, 500)
        XCTAssertEqual(decoded.costInputs.nFunctions, 25)
        XCTAssertEqual(decoded.costInputs.nDataSegmentBytes, 2048)
    }

    // MARK: - ContractCodeEntryExt Union Tests

    func testContractCodeEntryExtVoid() throws {
        let original = ContractCodeEntryExt.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCodeEntryExt.self, data: encoded)
        XCTAssertEqual(decoded.type(), 0)
        if case .void = decoded {
            // expected
        } else {
            XCTFail("Expected .void")
        }
    }

    func testContractCodeEntryExtWithV1() throws {
        let costInputs = ContractCodeCostInputsXDR(
            ext: .void,
            nInstructions: 100,
            nFunctions: 10,
            nGlobals: 2,
            nTableEntries: 1,
            nTypes: 5,
            nDataSegments: 0,
            nElemSegments: 0,
            nImports: 3,
            nExports: 1,
            nDataSegmentBytes: 512
        )
        let v1 = ContractCodeEntryExtV1(ext: .void, costInputs: costInputs)
        let original = ContractCodeEntryExt.v1(v1)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCodeEntryExt.self, data: encoded)
        XCTAssertEqual(decoded.type(), 1)
        if case .v1(let dV1) = decoded {
            XCTAssertEqual(dV1.costInputs.nInstructions, 100)
        } else {
            XCTFail("Expected .v1")
        }
    }

    // MARK: - ContractCodeEntryXDR Tests

    func testContractCodeEntryXDRWithVoidExt() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let code = Data(repeating: 0xBE, count: 128)
        let original = ContractCodeEntryXDR(
            ext: .void,
            hash: hash,
            code: code
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCodeEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.hash.wrapped, hash.wrapped)
        XCTAssertEqual(decoded.code, code)
    }

    func testContractCodeEntryXDRWithV1Ext() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let code = Data(repeating: 0xCA, count: 64)
        let costInputs = ContractCodeCostInputsXDR(
            ext: .void,
            nInstructions: 200,
            nFunctions: 5,
            nGlobals: 1,
            nTableEntries: 0,
            nTypes: 3,
            nDataSegments: 0,
            nElemSegments: 0,
            nImports: 2,
            nExports: 1,
            nDataSegmentBytes: 256
        )
        let v1 = ContractCodeEntryExtV1(ext: .void, costInputs: costInputs)
        let original = ContractCodeEntryXDR(
            ext: .v1(v1),
            hash: hash,
            code: code
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCodeEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.hash.wrapped, hash.wrapped)
        XCTAssertEqual(decoded.code, code)
        if case .v1(let dV1) = decoded.ext {
            XCTAssertEqual(dV1.costInputs.nInstructions, 200)
        } else {
            XCTFail("Expected .v1 ext")
        }
    }

    func testContractCodeEntryXDREmptyCode() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let original = ContractCodeEntryXDR(
            ext: .void,
            hash: hash,
            code: Data()
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCodeEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.code.count, 0)
    }

    // MARK: - TTLEntryXDR Tests

    func testTTLEntryXDRRoundTrip() throws {
        let keyHash = XDRTestHelpers.wrappedData32()
        let original = TTLEntryXDR(keyHash: keyHash, liveUntilLedgerSeq: 12345678)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TTLEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.keyHash.wrapped, keyHash.wrapped)
        XCTAssertEqual(decoded.liveUntilLedgerSeq, 12345678)
    }

    func testTTLEntryXDRMaxLedger() throws {
        let keyHash = XDRTestHelpers.wrappedData32()
        let original = TTLEntryXDR(keyHash: keyHash, liveUntilLedgerSeq: UInt32.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TTLEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.liveUntilLedgerSeq, UInt32.max)
    }

    // MARK: - SignerXDR Tests

    func testSignerXDRRoundTrip() throws {
        let key = SignerKeyXDR.ed25519(XDRTestHelpers.wrappedData32())
        let original = SignerXDR(key: key, weight: 5)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SignerXDR.self, data: encoded)
        XCTAssertEqual(decoded.weight, 5)
    }

    func testSignerXDRMaxWeight() throws {
        let key = SignerKeyXDR.ed25519(XDRTestHelpers.wrappedData32())
        let original = SignerXDR(key: key, weight: 255) // max meaningful weight
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SignerXDR.self, data: encoded)
        XCTAssertEqual(decoded.weight, 255)
    }

    // MARK: - Base64 Round-Trip Tests

    func testAccountEntryXDRBase64RoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let thresholds = XDRTestHelpers.wrappedData4()
        let original = AccountEntryXDR(
            accountID: pk,
            balance: 75_000_000,
            sequenceNumber: 555,
            numSubEntries: 0,
            flags: 0,
            homeDomain: "test.org",
            thresholds: thresholds,
            signers: [],
            ext: .void
        )
        let encoded = try XDREncoder.encode(original)
        let base64 = Data(encoded).base64EncodedString()
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(AccountEntryXDR.self, data: [UInt8](decodedData))
        XCTAssertEqual(decoded.balance, 75_000_000)
        XCTAssertEqual(decoded.homeDomain, "test.org")
    }

    func testClaimableBalanceEntryXDRBase64RoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let balanceID = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(XDRTestHelpers.wrappedData32())
        let claimant = ClaimantXDR.claimantTypeV0(
            ClaimantV0XDR(accountID: pk, predicate: .claimPredicateUnconditional)
        )
        let original = ClaimableBalanceEntryXDR(
            claimableBalanceID: balanceID,
            claimants: [claimant],
            asset: .native,
            amount: 999_999,
            ext: .void
        )
        let encoded = try XDREncoder.encode(original)
        let base64 = Data(encoded).base64EncodedString()
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(ClaimableBalanceEntryXDR.self, data: [UInt8](decodedData))
        XCTAssertEqual(decoded.amount, 999_999)
    }

    func testLiquidityPoolEntryXDRBase64RoundTrip() throws {
        let poolID = XDRTestHelpers.wrappedData32()
        let params = LiquidityPoolConstantProductParametersXDR(
            assetA: .native,
            assetB: .native,
            fee: 30
        )
        let cp = ConstantProductXDR(
            params: params,
            reserveA: 777,
            reserveB: 888,
            totalPoolShares: 333,
            poolSharesTrustLineCount: 5
        )
        let original = LiquidityPoolEntryXDR(
            liquidityPoolID: poolID,
            body: .constantProduct(cp)
        )
        let encoded = try XDREncoder.encode(original)
        let base64 = Data(encoded).base64EncodedString()
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(LiquidityPoolEntryXDR.self, data: [UInt8](decodedData))
        if case .constantProduct(let dCp) = decoded.body {
            XCTAssertEqual(dCp.reserveA, 777)
            XCTAssertEqual(dCp.reserveB, 888)
        } else {
            XCTFail("Expected .constantProduct")
        }
    }

    func testContractDataEntryXDRBase64RoundTrip() throws {
        let contractAddr = SCAddressXDR.contract(XDRTestHelpers.wrappedData32())
        let original = ContractDataEntryXDR(
            ext: .void,
            contract: contractAddr,
            key: .u32(7),
            durability: .persistent,
            val: .bool(true)
        )
        let encoded = try XDREncoder.encode(original)
        let base64 = Data(encoded).base64EncodedString()
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(ContractDataEntryXDR.self, data: [UInt8](decodedData))
        XCTAssertEqual(decoded.durability, .persistent)
    }

    func testTTLEntryXDRBase64RoundTrip() throws {
        let keyHash = XDRTestHelpers.wrappedData32()
        let original = TTLEntryXDR(keyHash: keyHash, liveUntilLedgerSeq: 999999)
        let encoded = try XDREncoder.encode(original)
        let base64 = Data(encoded).base64EncodedString()
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(TTLEntryXDR.self, data: [UInt8](decodedData))
        XCTAssertEqual(decoded.liveUntilLedgerSeq, 999999)
    }
}
