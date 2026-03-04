//
//  XDRLedgerEntriesP2UnitTests.swift
//  stellarsdkTests
//
//  Tests for types from the second half of Stellar-ledger-entries.x:
//  LedgerEntry, LedgerKey, BucketEntry, EnvelopeType, and related types.
//

import XCTest
import stellarsdk

class XDRLedgerEntriesP2UnitTests: XCTestCase {

    // MARK: - Helper: Build a minimal LedgerEntryXDR for reuse

    /// Builds a minimal TTL-based LedgerEntryXDR for use in composite tests.
    private func minimalTTLLedgerEntry() -> LedgerEntryXDR {
        let ttl = TTLEntryXDR(keyHash: XDRTestHelpers.wrappedData32(), liveUntilLedgerSeq: 500)
        return LedgerEntryXDR(
            lastModifiedLedgerSeq: 42,
            data: .ttl(ttl),
            reserved: .void
        )
    }

    /// Builds a minimal DataEntryXDR-based LedgerEntryXDR.
    private func minimalDataLedgerEntry() throws -> LedgerEntryXDR {
        let pk = try XDRTestHelpers.publicKey()
        let dataEntry = DataEntryXDR(
            accountID: pk,
            dataName: "testKey",
            dataValue: Data([0x01, 0x02])
        )
        return LedgerEntryXDR(
            lastModifiedLedgerSeq: 100,
            data: .data(dataEntry),
            reserved: .void
        )
    }

    // MARK: - Simple Enum Round-Trip Tests

    func testLedgerEntryTypeRoundTrip() throws {
        let allCases: [LedgerEntryType] = [
            .account, .trustline, .offer, .data, .claimableBalance,
            .liquidityPool, .contractData, .contractCode, .configSetting, .ttl
        ]
        for entry in allCases {
            let encoded = try XDREncoder.encode(entry)
            let decoded = try XDRDecoder.decode(LedgerEntryType.self, data: encoded)
            XCTAssertEqual(decoded, entry)
        }
    }

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

    func testEnvelopeTypeRoundTrip() throws {
        let allCases: [EnvelopeType] = [
            .txV0, .scp, .tx, .auth, .scpvalue, .txFeeBump,
            .opId, .poolRevokeOpId, .contractId, .sorobanAuthorization
        ]
        for et in allCases {
            let encoded = try XDREncoder.encode(et)
            let decoded = try XDRDecoder.decode(EnvelopeType.self, data: encoded)
            XCTAssertEqual(decoded, et)
        }
    }

    func testEnvelopeTypeRawValues() {
        XCTAssertEqual(EnvelopeType.txV0.rawValue, 0)
        XCTAssertEqual(EnvelopeType.scp.rawValue, 1)
        XCTAssertEqual(EnvelopeType.tx.rawValue, 2)
        XCTAssertEqual(EnvelopeType.auth.rawValue, 3)
        XCTAssertEqual(EnvelopeType.scpvalue.rawValue, 4)
        XCTAssertEqual(EnvelopeType.txFeeBump.rawValue, 5)
        XCTAssertEqual(EnvelopeType.opId.rawValue, 6)
        XCTAssertEqual(EnvelopeType.poolRevokeOpId.rawValue, 7)
        XCTAssertEqual(EnvelopeType.contractId.rawValue, 8)
        XCTAssertEqual(EnvelopeType.sorobanAuthorization.rawValue, 9)
    }

    func testBucketListTypeXDRRoundTrip() throws {
        for bt in [BucketListTypeXDR.live, .hotArchive] {
            let encoded = try XDREncoder.encode(bt)
            let decoded = try XDRDecoder.decode(BucketListTypeXDR.self, data: encoded)
            XCTAssertEqual(decoded, bt)
        }
        XCTAssertEqual(BucketListTypeXDR.live.rawValue, 0)
        XCTAssertEqual(BucketListTypeXDR.hotArchive.rawValue, 1)
    }

    func testBucketEntryTypeXDRRoundTrip() throws {
        let allCases: [BucketEntryTypeXDR] = [.metaentry, .liveentry, .deadentry, .initentry]
        for bt in allCases {
            let encoded = try XDREncoder.encode(bt)
            let decoded = try XDRDecoder.decode(BucketEntryTypeXDR.self, data: encoded)
            XCTAssertEqual(decoded, bt)
        }
    }

    func testBucketEntryTypeXDRRawValues() {
        XCTAssertEqual(BucketEntryTypeXDR.metaentry.rawValue, -1)
        XCTAssertEqual(BucketEntryTypeXDR.liveentry.rawValue, 0)
        XCTAssertEqual(BucketEntryTypeXDR.deadentry.rawValue, 1)
        XCTAssertEqual(BucketEntryTypeXDR.initentry.rawValue, 2)
    }

    func testHotArchiveBucketEntryTypeXDRRoundTrip() throws {
        let allCases: [HotArchiveBucketEntryTypeXDR] = [.metaentry, .archived, .live]
        for bt in allCases {
            let encoded = try XDREncoder.encode(bt)
            let decoded = try XDRDecoder.decode(HotArchiveBucketEntryTypeXDR.self, data: encoded)
            XCTAssertEqual(decoded, bt)
        }
    }

    func testHotArchiveBucketEntryTypeXDRRawValues() {
        XCTAssertEqual(HotArchiveBucketEntryTypeXDR.metaentry.rawValue, -1)
        XCTAssertEqual(HotArchiveBucketEntryTypeXDR.archived.rawValue, 0)
        XCTAssertEqual(HotArchiveBucketEntryTypeXDR.live.rawValue, 1)
    }

    func testThresholdIndexesXDRRoundTrip() throws {
        let allCases: [ThresholdIndexesXDR] = [.masterWeight, .low, .med, .high]
        for idx in allCases {
            let encoded = try XDREncoder.encode(idx)
            let decoded = try XDRDecoder.decode(ThresholdIndexesXDR.self, data: encoded)
            XCTAssertEqual(decoded, idx)
        }
    }

    func testThresholdIndexesXDRRawValues() {
        XCTAssertEqual(ThresholdIndexesXDR.masterWeight.rawValue, 0)
        XCTAssertEqual(ThresholdIndexesXDR.low.rawValue, 1)
        XCTAssertEqual(ThresholdIndexesXDR.med.rawValue, 2)
        XCTAssertEqual(ThresholdIndexesXDR.high.rawValue, 3)
    }

    func testLedgerEntryChangeTypeRoundTrip() throws {
        let allCases: [LedgerEntryChangeType] = [
            .ledgerEntryCreated, .ledgerEntryUpdated, .ledgerEntryRemoved,
            .ledgerEntryState, .ledgerEntryRestore
        ]
        for ct in allCases {
            let encoded = try XDREncoder.encode(ct)
            let decoded = try XDRDecoder.decode(LedgerEntryChangeType.self, data: encoded)
            XCTAssertEqual(decoded, ct)
        }
    }

    func testLedgerEntryChangeTypeRawValues() {
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryCreated.rawValue, 0)
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryUpdated.rawValue, 1)
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryRemoved.rawValue, 2)
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryState.rawValue, 3)
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryRestore.rawValue, 4)
    }

    // MARK: - LedgerEntryExtensionV1 Tests

    func testLedgerEntryExtensionV1WithSponsor() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = LedgerEntryExtensionV1(signerSponsoringID: pk)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryExtensionV1.self, data: encoded)
        XCTAssertNotNil(decoded.signerSponsoringID)
        XCTAssertEqual(decoded.signerSponsoringID?.accountId, pk.accountId)
        XCTAssertEqual(decoded.reserved, 0)
    }

    func testLedgerEntryExtensionV1WithoutSponsor() throws {
        let original = LedgerEntryExtensionV1(signerSponsoringID: nil)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryExtensionV1.self, data: encoded)
        XCTAssertNil(decoded.signerSponsoringID)
        XCTAssertEqual(decoded.reserved, 0)
    }

    // MARK: - LedgerEntryExtensionV1ExtXDR Tests

    func testLedgerEntryExtensionV1ExtXDRVoid() throws {
        let original = LedgerEntryExtensionV1ExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryExtensionV1ExtXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 0)
        if case .void = decoded {
            // expected
        } else {
            XCTFail("Expected .void")
        }
    }

    // MARK: - LedgerEntryExtXDR Union Tests

    func testLedgerEntryExtXDRVoid() throws {
        let original = LedgerEntryExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryExtXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 0)
        if case .void = decoded {
            // expected
        } else {
            XCTFail("Expected .void")
        }
    }

    func testLedgerEntryExtXDRWithV1() throws {
        let pk = try XDRTestHelpers.publicKey()
        let v1 = LedgerEntryExtensionV1(signerSponsoringID: pk)
        let original = LedgerEntryExtXDR.ledgerEntryExtensionV1(v1)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryExtXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 1)
        if case .ledgerEntryExtensionV1(let dV1) = decoded {
            XCTAssertNotNil(dV1.signerSponsoringID)
            XCTAssertEqual(dV1.signerSponsoringID?.accountId, pk.accountId)
        } else {
            XCTFail("Expected .ledgerEntryExtensionV1")
        }
    }

    func testLedgerEntryExtXDRWithV1NilSponsor() throws {
        let v1 = LedgerEntryExtensionV1(signerSponsoringID: nil)
        let original = LedgerEntryExtXDR.ledgerEntryExtensionV1(v1)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryExtXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 1)
        if case .ledgerEntryExtensionV1(let dV1) = decoded {
            XCTAssertNil(dV1.signerSponsoringID)
        } else {
            XCTFail("Expected .ledgerEntryExtensionV1")
        }
    }

    // MARK: - LedgerEntryDataXDR Union Tests

    func testLedgerEntryDataXDRTTL() throws {
        let ttl = TTLEntryXDR(keyHash: XDRTestHelpers.wrappedData32(), liveUntilLedgerSeq: 12345)
        let original = LedgerEntryDataXDR.ttl(ttl)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.ttl.rawValue)
        if case .ttl(let dTTL) = decoded {
            XCTAssertEqual(dTTL.liveUntilLedgerSeq, 12345)
        } else {
            XCTFail("Expected .ttl")
        }
    }

    func testLedgerEntryDataXDRData() throws {
        let pk = try XDRTestHelpers.publicKey()
        let dataEntry = DataEntryXDR(accountID: pk, dataName: "info", dataValue: Data([0xAA]))
        let original = LedgerEntryDataXDR.data(dataEntry)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.data.rawValue)
        if case .data(let dEntry) = decoded {
            XCTAssertEqual(dEntry.dataName, "info")
            XCTAssertEqual(dEntry.dataValue, Data([0xAA]))
        } else {
            XCTFail("Expected .data")
        }
    }

    func testLedgerEntryDataXDROffer() throws {
        let pk = try XDRTestHelpers.publicKey()
        let offer = OfferEntryXDR(
            sellerID: pk,
            offerID: 12345,
            selling: .native,
            buying: .native,
            amount: 1_000_000,
            price: PriceXDR(n: 1, d: 2),
            flags: 0
        )
        let original = LedgerEntryDataXDR.offer(offer)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.offer.rawValue)
        if case .offer(let dOffer) = decoded {
            XCTAssertEqual(dOffer.offerID, 12345)
            XCTAssertEqual(dOffer.amount, 1_000_000)
            XCTAssertEqual(dOffer.price.n, 1)
            XCTAssertEqual(dOffer.price.d, 2)
        } else {
            XCTFail("Expected .offer")
        }
    }

    func testLedgerEntryDataXDRContractData() throws {
        let pk = try XDRTestHelpers.publicKey()
        let contractData = ContractDataEntryXDR(
            ext: .void,
            contract: .account(pk),
            key: .u32(7),
            durability: .persistent,
            val: .bool(true)
        )
        let original = LedgerEntryDataXDR.contractData(contractData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.contractData.rawValue)
        if case .contractData(let dCD) = decoded {
            XCTAssertEqual(dCD.durability, .persistent)
        } else {
            XCTFail("Expected .contractData")
        }
    }

    func testLedgerEntryDataXDRContractCode() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let code = Data(repeating: 0xBE, count: 64)
        let codeEntry = ContractCodeEntryXDR(ext: .void, hash: hash, code: code)
        let original = LedgerEntryDataXDR.contractCode(codeEntry)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.contractCode.rawValue)
        if case .contractCode(let dCC) = decoded {
            XCTAssertEqual(dCC.code, code)
            XCTAssertEqual(dCC.hash.wrapped, hash.wrapped)
        } else {
            XCTFail("Expected .contractCode")
        }
    }

    func testLedgerEntryDataXDRConfigSetting() throws {
        let original = LedgerEntryDataXDR.configSetting(.contractMaxSizeBytes(65536))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.configSetting.rawValue)
        if case .configSetting(let dCS) = decoded {
            if case .contractMaxSizeBytes(let v) = dCS {
                XCTAssertEqual(v, 65536)
            } else {
                XCTFail("Expected .contractMaxSizeBytes")
            }
        } else {
            XCTFail("Expected .configSetting")
        }
    }

    func testLedgerEntryDataXDRAccount() throws {
        let pk = try XDRTestHelpers.publicKey()
        let thresholds = XDRTestHelpers.wrappedData4()
        let account = AccountEntryXDR(
            accountID: pk,
            balance: 50_000_000,
            sequenceNumber: 10,
            numSubEntries: 0,
            flags: 0,
            homeDomain: "",
            thresholds: thresholds,
            signers: [],
            ext: .void
        )
        let original = LedgerEntryDataXDR.account(account)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.account.rawValue)
        if case .account(let dAcc) = decoded {
            XCTAssertEqual(dAcc.balance, 50_000_000)
            XCTAssertEqual(dAcc.sequenceNumber, 10)
        } else {
            XCTFail("Expected .account")
        }
    }

    func testLedgerEntryDataXDRTrustline() throws {
        let pk = try XDRTestHelpers.publicKey()
        let trustline = TrustlineEntryXDR(
            accountID: pk,
            asset: .native,
            balance: 1_000_000,
            limit: 10_000_000,
            flags: 1,
            reserved: .void
        )
        let original = LedgerEntryDataXDR.trustline(trustline)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.trustline.rawValue)
        if case .trustline(let dTL) = decoded {
            XCTAssertEqual(dTL.balance, 1_000_000)
            XCTAssertEqual(dTL.limit, 10_000_000)
            XCTAssertEqual(dTL.flags, 1)
        } else {
            XCTFail("Expected .trustline")
        }
    }

    func testLedgerEntryDataXDRClaimableBalance() throws {
        let pk = try XDRTestHelpers.publicKey()
        let balanceID = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(XDRTestHelpers.wrappedData32())
        let claimant = ClaimantXDR.claimantTypeV0(
            ClaimantV0XDR(accountID: pk, predicate: .claimPredicateUnconditional)
        )
        let cbEntry = ClaimableBalanceEntryXDR(
            claimableBalanceID: balanceID,
            claimants: [claimant],
            asset: .native,
            amount: 250_000,
            ext: .void
        )
        let original = LedgerEntryDataXDR.claimableBalance(cbEntry)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.claimableBalance.rawValue)
        if case .claimableBalance(let dCB) = decoded {
            XCTAssertEqual(dCB.amount, 250_000)
            XCTAssertEqual(dCB.claimants.count, 1)
        } else {
            XCTFail("Expected .claimableBalance")
        }
    }

    func testLedgerEntryDataXDRLiquidityPool() throws {
        let poolID = XDRTestHelpers.wrappedData32()
        let params = LiquidityPoolConstantProductParametersXDR(assetA: .native, assetB: .native, fee: 30)
        let cp = ConstantProductXDR(
            params: params, reserveA: 100, reserveB: 200,
            totalPoolShares: 50, poolSharesTrustLineCount: 2
        )
        let lpEntry = LiquidityPoolEntryXDR(liquidityPoolID: poolID, body: .constantProduct(cp))
        let original = LedgerEntryDataXDR.liquidityPool(lpEntry)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.liquidityPool.rawValue)
        if case .liquidityPool(let dLP) = decoded {
            XCTAssertEqual(dLP.liquidityPoolID.wrapped, poolID.wrapped)
        } else {
            XCTFail("Expected .liquidityPool")
        }
    }

    // MARK: - LedgerEntryXDR Tests

    func testLedgerEntryXDRWithTTLAndVoidExt() throws {
        let original = minimalTTLLedgerEntry()
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.lastModifiedLedgerSeq, 42)
        XCTAssertEqual(decoded.reserved.type(), 0)
        if case .ttl(let dTTL) = decoded.data {
            XCTAssertEqual(dTTL.liveUntilLedgerSeq, 500)
        } else {
            XCTFail("Expected .ttl data")
        }
    }

    func testLedgerEntryXDRWithV1Extension() throws {
        let pk = try XDRTestHelpers.publicKey()
        let v1 = LedgerEntryExtensionV1(signerSponsoringID: pk)
        let ttl = TTLEntryXDR(keyHash: XDRTestHelpers.wrappedData32(), liveUntilLedgerSeq: 99999)
        let original = LedgerEntryXDR(
            lastModifiedLedgerSeq: 7777,
            data: .ttl(ttl),
            reserved: .ledgerEntryExtensionV1(v1)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.lastModifiedLedgerSeq, 7777)
        XCTAssertEqual(decoded.reserved.type(), 1)
        if case .ledgerEntryExtensionV1(let dV1) = decoded.reserved {
            XCTAssertNotNil(dV1.signerSponsoringID)
        } else {
            XCTFail("Expected .ledgerEntryExtensionV1 in reserved")
        }
    }

    func testLedgerEntryXDRWithDataEntry() throws {
        let original = try minimalDataLedgerEntry()
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.lastModifiedLedgerSeq, 100)
        if case .data(let dEntry) = decoded.data {
            XCTAssertEqual(dEntry.dataName, "testKey")
        } else {
            XCTFail("Expected .data")
        }
    }

    func testLedgerEntryXDRWithOfferEntry() throws {
        let pk = try XDRTestHelpers.publicKey()
        let offer = OfferEntryXDR(
            sellerID: pk,
            offerID: 888,
            selling: .native,
            buying: .native,
            amount: 5_000_000,
            price: PriceXDR(n: 2, d: 3),
            flags: 1
        )
        let original = LedgerEntryXDR(
            lastModifiedLedgerSeq: 999,
            data: .offer(offer),
            reserved: .void
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.lastModifiedLedgerSeq, 999)
        if case .offer(let dOffer) = decoded.data {
            XCTAssertEqual(dOffer.offerID, 888)
            XCTAssertEqual(dOffer.amount, 5_000_000)
        } else {
            XCTFail("Expected .offer data")
        }
    }

    func testLedgerEntryXDRMaxLedgerSeq() throws {
        let ttl = TTLEntryXDR(keyHash: XDRTestHelpers.wrappedData32(), liveUntilLedgerSeq: 1)
        let original = LedgerEntryXDR(
            lastModifiedLedgerSeq: UInt32.max,
            data: .ttl(ttl),
            reserved: .void
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.lastModifiedLedgerSeq, UInt32.max)
    }

    // MARK: - LedgerKeyXDR Union Tests: All 10 Arms

    func testLedgerKeyXDRAccount() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = LedgerKeyXDR.account(LedgerKeyAccountXDR(accountID: pk))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.account.rawValue)
        if case .account(let dAcc) = decoded {
            XCTAssertEqual(dAcc.accountID.accountId, pk.accountId)
        } else {
            XCTFail("Expected .account")
        }
    }

    func testLedgerKeyXDRTrustline() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = LedgerKeyXDR.trustline(
            LedgerKeyTrustLineXDR(accountID: pk, asset: .native)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.trustline.rawValue)
        if case .trustline(let dTL) = decoded {
            XCTAssertEqual(dTL.accountID.accountId, pk.accountId)
        } else {
            XCTFail("Expected .trustline")
        }
    }

    func testLedgerKeyXDRTrustlineWithPoolShare() throws {
        let pk = try XDRTestHelpers.publicKey()
        let poolID = XDRTestHelpers.wrappedData32()
        let original = LedgerKeyXDR.trustline(
            LedgerKeyTrustLineXDR(accountID: pk, asset: .poolShare(poolID))
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.trustline.rawValue)
        if case .trustline(let dTL) = decoded {
            if case .poolShare(let dPool) = dTL.asset {
                XCTAssertEqual(dPool.wrapped, poolID.wrapped)
            } else {
                XCTFail("Expected .poolShare asset")
            }
        } else {
            XCTFail("Expected .trustline")
        }
    }

    func testLedgerKeyXDROffer() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = LedgerKeyXDR.offer(LedgerKeyOfferXDR(sellerID: pk, offerID: 77777))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.offer.rawValue)
        if case .offer(let dOffer) = decoded {
            XCTAssertEqual(dOffer.offerID, 77777)
            XCTAssertEqual(dOffer.sellerID.accountId, pk.accountId)
        } else {
            XCTFail("Expected .offer")
        }
    }

    func testLedgerKeyXDRData() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = LedgerKeyXDR.data(LedgerKeyDataXDR(accountID: pk, dataName: "myKey"))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.data.rawValue)
        if case .data(let dData) = decoded {
            XCTAssertEqual(dData.dataName, "myKey")
            XCTAssertEqual(dData.accountID.accountId, pk.accountId)
        } else {
            XCTFail("Expected .data")
        }
    }

    func testLedgerKeyXDRClaimableBalance() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let balanceID = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(hash)
        let original = LedgerKeyXDR.claimableBalance(
            LedgerKeyClaimableBalanceXDR(balanceID: balanceID)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.claimableBalance.rawValue)
        if case .claimableBalance(let dCB) = decoded {
            if case .claimableBalanceIDTypeV0(let dHash) = dCB.balanceID {
                XCTAssertEqual(dHash.wrapped, hash.wrapped)
            } else {
                XCTFail("Expected .claimableBalanceIDTypeV0")
            }
        } else {
            XCTFail("Expected .claimableBalance")
        }
    }

    func testLedgerKeyXDRLiquidityPool() throws {
        let poolID = XDRTestHelpers.wrappedData32()
        let original = LedgerKeyXDR.liquidityPool(
            LedgerKeyLiquidityPoolXDR(liquidityPoolID: poolID)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.liquidityPool.rawValue)
        if case .liquidityPool(let dLP) = decoded {
            XCTAssertEqual(dLP.liquidityPoolID.wrapped, poolID.wrapped)
        } else {
            XCTFail("Expected .liquidityPool")
        }
    }

    func testLedgerKeyXDRContractData() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = LedgerKeyXDR.contractData(
            LedgerKeyContractDataXDR(
                contract: .account(pk),
                key: .symbol("balance"),
                durability: .persistent
            )
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.contractData.rawValue)
        if case .contractData(let dCD) = decoded {
            XCTAssertEqual(dCD.durability, .persistent)
            if case .symbol(let s) = dCD.key {
                XCTAssertEqual(s, "balance")
            } else {
                XCTFail("Expected .symbol key")
            }
        } else {
            XCTFail("Expected .contractData")
        }
    }

    func testLedgerKeyXDRContractDataTemporary() throws {
        let contractAddr = SCAddressXDR.contract(XDRTestHelpers.wrappedData32())
        let original = LedgerKeyXDR.contractData(
            LedgerKeyContractDataXDR(
                contract: contractAddr,
                key: .u32(99),
                durability: .temporary
            )
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)
        if case .contractData(let dCD) = decoded {
            XCTAssertEqual(dCD.durability, .temporary)
            if case .u32(let v) = dCD.key {
                XCTAssertEqual(v, 99)
            } else {
                XCTFail("Expected .u32 key")
            }
        } else {
            XCTFail("Expected .contractData")
        }
    }

    func testLedgerKeyXDRContractCode() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let original = LedgerKeyXDR.contractCode(LedgerKeyContractCodeXDR(hash: hash))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.contractCode.rawValue)
        if case .contractCode(let dCC) = decoded {
            XCTAssertEqual(dCC.hash.wrapped, hash.wrapped)
        } else {
            XCTFail("Expected .contractCode")
        }
    }

    func testLedgerKeyXDRConfigSetting() throws {
        let original = LedgerKeyXDR.configSetting(LedgerKeyConfigSettingXDR(configSettingID: 5))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.configSetting.rawValue)
        if case .configSetting(let dCS) = decoded {
            XCTAssertEqual(dCS.configSettingID, 5)
        } else {
            XCTFail("Expected .configSetting")
        }
    }

    func testLedgerKeyXDRTTL() throws {
        let keyHash = XDRTestHelpers.wrappedData32()
        let original = LedgerKeyXDR.ttl(LedgerKeyTTLXDR(keyHash: keyHash))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryType.ttl.rawValue)
        if case .ttl(let dTTL) = decoded {
            XCTAssertEqual(dTTL.keyHash.wrapped, keyHash.wrapped)
        } else {
            XCTFail("Expected .ttl")
        }
    }

    // MARK: - LedgerKey Sub-Struct Tests

    func testLedgerKeyAccountXDRRoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = LedgerKeyAccountXDR(accountID: pk)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyAccountXDR.self, data: encoded)
        XCTAssertEqual(decoded.accountID.accountId, pk.accountId)
    }

    func testLedgerKeyTrustLineXDRRoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = LedgerKeyTrustLineXDR(accountID: pk, asset: .native)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyTrustLineXDR.self, data: encoded)
        XCTAssertEqual(decoded.accountID.accountId, pk.accountId)
    }

    func testLedgerKeyOfferXDRRoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = LedgerKeyOfferXDR(sellerID: pk, offerID: 999_999)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyOfferXDR.self, data: encoded)
        XCTAssertEqual(decoded.offerID, 999_999)
        XCTAssertEqual(decoded.sellerID.accountId, pk.accountId)
    }

    func testLedgerKeyDataXDRRoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = LedgerKeyDataXDR(accountID: pk, dataName: "longDataName12345")
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.dataName, "longDataName12345")
    }

    func testLedgerKeyClaimableBalanceXDRRoundTrip() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let balanceID = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(hash)
        let original = LedgerKeyClaimableBalanceXDR(balanceID: balanceID)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyClaimableBalanceXDR.self, data: encoded)
        if case .claimableBalanceIDTypeV0(let dHash) = decoded.balanceID {
            XCTAssertEqual(dHash.wrapped, hash.wrapped)
        } else {
            XCTFail("Expected .claimableBalanceIDTypeV0")
        }
    }

    func testLedgerKeyLiquidityPoolXDRRoundTrip() throws {
        let poolID = XDRTestHelpers.wrappedData32()
        let original = LedgerKeyLiquidityPoolXDR(liquidityPoolID: poolID)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyLiquidityPoolXDR.self, data: encoded)
        XCTAssertEqual(decoded.liquidityPoolID.wrapped, poolID.wrapped)
    }

    func testLedgerKeyContractDataXDRRoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = LedgerKeyContractDataXDR(
            contract: .account(pk),
            key: .u64(12345678),
            durability: .temporary
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyContractDataXDR.self, data: encoded)
        XCTAssertEqual(decoded.durability, .temporary)
        if case .u64(let v) = decoded.key {
            XCTAssertEqual(v, 12345678)
        } else {
            XCTFail("Expected .u64 key")
        }
    }

    func testLedgerKeyContractCodeXDRRoundTrip() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let original = LedgerKeyContractCodeXDR(hash: hash)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyContractCodeXDR.self, data: encoded)
        XCTAssertEqual(decoded.hash.wrapped, hash.wrapped)
    }

    func testLedgerKeyConfigSettingXDRRoundTrip() throws {
        let original = LedgerKeyConfigSettingXDR(configSettingID: 8)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyConfigSettingXDR.self, data: encoded)
        XCTAssertEqual(decoded.configSettingID, 8)
    }

    func testLedgerKeyConfigSettingXDRNegativeID() throws {
        let original = LedgerKeyConfigSettingXDR(configSettingID: -1)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyConfigSettingXDR.self, data: encoded)
        XCTAssertEqual(decoded.configSettingID, -1)
    }

    func testLedgerKeyTTLXDRRoundTrip() throws {
        let keyHash = XDRTestHelpers.wrappedData32()
        let original = LedgerKeyTTLXDR(keyHash: keyHash)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerKeyTTLXDR.self, data: encoded)
        XCTAssertEqual(decoded.keyHash.wrapped, keyHash.wrapped)
    }

    // MARK: - BucketMetadataXDR Tests

    func testBucketMetadataXDRWithVoidExt() throws {
        let original = BucketMetadataXDR(ledgerVersion: 21, ext: .void)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BucketMetadataXDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerVersion, 21)
        XCTAssertEqual(decoded.ext.type(), 0)
    }

    func testBucketMetadataXDRWithBucketListType() throws {
        let original = BucketMetadataXDR(
            ledgerVersion: 22,
            ext: .bucketListType(.hotArchive)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BucketMetadataXDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerVersion, 22)
        XCTAssertEqual(decoded.ext.type(), 1)
        if case .bucketListType(let blt) = decoded.ext {
            XCTAssertEqual(blt, .hotArchive)
        } else {
            XCTFail("Expected .bucketListType")
        }
    }

    func testBucketMetadataXDRWithLiveBucketListType() throws {
        let original = BucketMetadataXDR(
            ledgerVersion: 20,
            ext: .bucketListType(.live)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BucketMetadataXDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerVersion, 20)
        if case .bucketListType(let blt) = decoded.ext {
            XCTAssertEqual(blt, .live)
        } else {
            XCTFail("Expected .bucketListType(.live)")
        }
    }

    // MARK: - BucketMetadataXDRExtXDR Tests

    func testBucketMetadataXDRExtXDRVoid() throws {
        let original = BucketMetadataXDRExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BucketMetadataXDRExtXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 0)
        if case .void = decoded {
            // expected
        } else {
            XCTFail("Expected .void")
        }
    }

    func testBucketMetadataXDRExtXDRWithBucketListType() throws {
        let original = BucketMetadataXDRExtXDR.bucketListType(.hotArchive)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BucketMetadataXDRExtXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), 1)
        if case .bucketListType(let blt) = decoded {
            XCTAssertEqual(blt, .hotArchive)
        } else {
            XCTFail("Expected .bucketListType(.hotArchive)")
        }
    }

    // MARK: - BucketEntryXDR Union Tests

    func testBucketEntryXDRMetaEntry() throws {
        let meta = BucketMetadataXDR(ledgerVersion: 21, ext: .void)
        let original = BucketEntryXDR.metaEntry(meta)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BucketEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), BucketEntryTypeXDR.metaentry.rawValue)
        if case .metaEntry(let dMeta) = decoded {
            XCTAssertEqual(dMeta.ledgerVersion, 21)
        } else {
            XCTFail("Expected .metaEntry")
        }
    }

    func testBucketEntryXDRLiveEntry() throws {
        let entry = minimalTTLLedgerEntry()
        let original = BucketEntryXDR.liveentry(entry)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BucketEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), BucketEntryTypeXDR.liveentry.rawValue)
        if case .liveentry(let dEntry) = decoded {
            XCTAssertEqual(dEntry.lastModifiedLedgerSeq, 42)
        } else {
            XCTFail("Expected .liveentry")
        }
    }

    func testBucketEntryXDRInitEntry() throws {
        let entry = minimalTTLLedgerEntry()
        let original = BucketEntryXDR.initentry(entry)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BucketEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), BucketEntryTypeXDR.initentry.rawValue)
        if case .initentry(let dEntry) = decoded {
            XCTAssertEqual(dEntry.lastModifiedLedgerSeq, 42)
        } else {
            XCTFail("Expected .initentry")
        }
    }

    func testBucketEntryXDRDeadEntry() throws {
        let pk = try XDRTestHelpers.publicKey()
        let ledgerKey = LedgerKeyXDR.account(LedgerKeyAccountXDR(accountID: pk))
        let original = BucketEntryXDR.deadEntry(ledgerKey)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BucketEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), BucketEntryTypeXDR.deadentry.rawValue)
        if case .deadEntry(let dKey) = decoded {
            XCTAssertEqual(dKey.type(), LedgerEntryType.account.rawValue)
        } else {
            XCTFail("Expected .deadEntry")
        }
    }

    // MARK: - HotArchiveBucketEntryXDR Union Tests

    func testHotArchiveBucketEntryXDRArchivedEntry() throws {
        let entry = minimalTTLLedgerEntry()
        let original = HotArchiveBucketEntryXDR.archivedEntry(entry)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HotArchiveBucketEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), HotArchiveBucketEntryTypeXDR.archived.rawValue)
        if case .archivedEntry(let dEntry) = decoded {
            XCTAssertEqual(dEntry.lastModifiedLedgerSeq, 42)
            if case .ttl(let dTTL) = dEntry.data {
                XCTAssertEqual(dTTL.liveUntilLedgerSeq, 500)
            } else {
                XCTFail("Expected .ttl data in archived entry")
            }
        } else {
            XCTFail("Expected .archivedEntry")
        }
    }

    func testHotArchiveBucketEntryXDRKey() throws {
        let pk = try XDRTestHelpers.publicKey()
        let ledgerKey = LedgerKeyXDR.account(LedgerKeyAccountXDR(accountID: pk))
        let original = HotArchiveBucketEntryXDR.key(ledgerKey)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HotArchiveBucketEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), HotArchiveBucketEntryTypeXDR.live.rawValue)
        if case .key(let dKey) = decoded {
            XCTAssertEqual(dKey.type(), LedgerEntryType.account.rawValue)
        } else {
            XCTFail("Expected .key")
        }
    }

    func testHotArchiveBucketEntryXDRMetaEntry() throws {
        let meta = BucketMetadataXDR(ledgerVersion: 23, ext: .bucketListType(.hotArchive))
        let original = HotArchiveBucketEntryXDR.metaEntry(meta)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HotArchiveBucketEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), HotArchiveBucketEntryTypeXDR.metaentry.rawValue)
        if case .metaEntry(let dMeta) = decoded {
            XCTAssertEqual(dMeta.ledgerVersion, 23)
            if case .bucketListType(let blt) = dMeta.ext {
                XCTAssertEqual(blt, .hotArchive)
            } else {
                XCTFail("Expected .bucketListType in meta ext")
            }
        } else {
            XCTFail("Expected .metaEntry")
        }
    }

    // MARK: - LedgerEntryChangeXDR Union Tests

    func testLedgerEntryChangeXDRCreated() throws {
        let entry = minimalTTLLedgerEntry()
        let original = LedgerEntryChangeXDR.created(entry)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryChangeXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryChangeType.ledgerEntryCreated.rawValue)
        if case .created(let dEntry) = decoded {
            XCTAssertEqual(dEntry.lastModifiedLedgerSeq, 42)
        } else {
            XCTFail("Expected .created")
        }
    }

    func testLedgerEntryChangeXDRUpdated() throws {
        let entry = minimalTTLLedgerEntry()
        let original = LedgerEntryChangeXDR.updated(entry)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryChangeXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryChangeType.ledgerEntryUpdated.rawValue)
        if case .updated(let dEntry) = decoded {
            XCTAssertEqual(dEntry.lastModifiedLedgerSeq, 42)
        } else {
            XCTFail("Expected .updated")
        }
    }

    func testLedgerEntryChangeXDRRemoved() throws {
        let pk = try XDRTestHelpers.publicKey()
        let ledgerKey = LedgerKeyXDR.account(LedgerKeyAccountXDR(accountID: pk))
        let original = LedgerEntryChangeXDR.removed(ledgerKey)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryChangeXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryChangeType.ledgerEntryRemoved.rawValue)
        if case .removed(let dKey) = decoded {
            XCTAssertEqual(dKey.type(), LedgerEntryType.account.rawValue)
        } else {
            XCTFail("Expected .removed")
        }
    }

    func testLedgerEntryChangeXDRState() throws {
        let entry = minimalTTLLedgerEntry()
        let original = LedgerEntryChangeXDR.state(entry)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryChangeXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryChangeType.ledgerEntryState.rawValue)
        if case .state(let dEntry) = decoded {
            XCTAssertEqual(dEntry.lastModifiedLedgerSeq, 42)
        } else {
            XCTFail("Expected .state")
        }
    }

    func testLedgerEntryChangeXDRRestored() throws {
        let entry = minimalTTLLedgerEntry()
        let original = LedgerEntryChangeXDR.restored(entry)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryChangeXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), LedgerEntryChangeType.ledgerEntryRestore.rawValue)
        if case .restored(let dEntry) = decoded {
            XCTAssertEqual(dEntry.lastModifiedLedgerSeq, 42)
        } else {
            XCTFail("Expected .restored")
        }
    }

    // MARK: - LedgerEntryChangesXDR Tests

    func testLedgerEntryChangesXDREmptyArray() throws {
        let original = LedgerEntryChangesXDR(LedgerEntryChanges: [])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryChangesXDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerEntryChanges.count, 0)
    }

    func testLedgerEntryChangesXDRMultipleChanges() throws {
        let pk = try XDRTestHelpers.publicKey()
        let entry = minimalTTLLedgerEntry()
        let ledgerKey = LedgerKeyXDR.account(LedgerKeyAccountXDR(accountID: pk))
        let changes: [LedgerEntryChangeXDR] = [
            .state(entry),
            .created(entry),
            .removed(ledgerKey)
        ]
        let original = LedgerEntryChangesXDR(LedgerEntryChanges: changes)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryChangesXDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerEntryChanges.count, 3)
        XCTAssertEqual(decoded.ledgerEntryChanges[0].type(), LedgerEntryChangeType.ledgerEntryState.rawValue)
        XCTAssertEqual(decoded.ledgerEntryChanges[1].type(), LedgerEntryChangeType.ledgerEntryCreated.rawValue)
        XCTAssertEqual(decoded.ledgerEntryChanges[2].type(), LedgerEntryChangeType.ledgerEntryRemoved.rawValue)
    }

    // MARK: - Base64 Round-Trip Tests

    func testLedgerEntryXDRBase64RoundTrip() throws {
        let original = minimalTTLLedgerEntry()
        let encoded = try XDREncoder.encode(original)
        let base64 = Data(encoded).base64EncodedString()
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(LedgerEntryXDR.self, data: [UInt8](decodedData))
        XCTAssertEqual(decoded.lastModifiedLedgerSeq, 42)
        if case .ttl(let dTTL) = decoded.data {
            XCTAssertEqual(dTTL.liveUntilLedgerSeq, 500)
        } else {
            XCTFail("Expected .ttl data after base64 round-trip")
        }
    }

    func testLedgerKeyXDRBase64RoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = LedgerKeyXDR.offer(LedgerKeyOfferXDR(sellerID: pk, offerID: 54321))
        let encoded = try XDREncoder.encode(original)
        let base64 = Data(encoded).base64EncodedString()
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(LedgerKeyXDR.self, data: [UInt8](decodedData))
        if case .offer(let dOffer) = decoded {
            XCTAssertEqual(dOffer.offerID, 54321)
        } else {
            XCTFail("Expected .offer after base64 round-trip")
        }
    }

    func testBucketEntryXDRBase64RoundTrip() throws {
        let meta = BucketMetadataXDR(ledgerVersion: 21, ext: .void)
        let original = BucketEntryXDR.metaEntry(meta)
        let encoded = try XDREncoder.encode(original)
        let base64 = Data(encoded).base64EncodedString()
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(BucketEntryXDR.self, data: [UInt8](decodedData))
        if case .metaEntry(let dMeta) = decoded {
            XCTAssertEqual(dMeta.ledgerVersion, 21)
        } else {
            XCTFail("Expected .metaEntry after base64 round-trip")
        }
    }

    func testHotArchiveBucketEntryXDRBase64RoundTrip() throws {
        let meta = BucketMetadataXDR(ledgerVersion: 23, ext: .bucketListType(.hotArchive))
        let original = HotArchiveBucketEntryXDR.metaEntry(meta)
        let encoded = try XDREncoder.encode(original)
        let base64 = Data(encoded).base64EncodedString()
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(HotArchiveBucketEntryXDR.self, data: [UInt8](decodedData))
        if case .metaEntry(let dMeta) = decoded {
            XCTAssertEqual(dMeta.ledgerVersion, 23)
        } else {
            XCTFail("Expected .metaEntry after base64 round-trip")
        }
    }

    func testLedgerEntryChangesXDRBase64RoundTrip() throws {
        let entry = minimalTTLLedgerEntry()
        let changes: [LedgerEntryChangeXDR] = [.created(entry), .updated(entry)]
        let original = LedgerEntryChangesXDR(LedgerEntryChanges: changes)
        let encoded = try XDREncoder.encode(original)
        let base64 = Data(encoded).base64EncodedString()
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(LedgerEntryChangesXDR.self, data: [UInt8](decodedData))
        XCTAssertEqual(decoded.ledgerEntryChanges.count, 2)
    }

    func testLedgerKeyContractDataXDRBase64RoundTrip() throws {
        let contractAddr = SCAddressXDR.contract(XDRTestHelpers.wrappedData32())
        let original = LedgerKeyContractDataXDR(
            contract: contractAddr,
            key: .symbol("counter"),
            durability: .persistent
        )
        let encoded = try XDREncoder.encode(original)
        let base64 = Data(encoded).base64EncodedString()
        let decodedData = Data(base64Encoded: base64)!
        let decoded = try XDRDecoder.decode(LedgerKeyContractDataXDR.self, data: [UInt8](decodedData))
        XCTAssertEqual(decoded.durability, .persistent)
        if case .symbol(let s) = decoded.key {
            XCTAssertEqual(s, "counter")
        } else {
            XCTFail("Expected .symbol key after base64 round-trip")
        }
    }
}
