//
//  XDRInternalExporterUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

// Batch 15 (FINAL): Internal, Exporter, and straggler types
final class XDRInternalExporterUnitTests: XCTestCase {

    // =========================================================================
    // MARK: - Stellar-internal.x types
    // =========================================================================

    // MARK: - StoredTransactionSetXDR

    func testStoredTransactionSetTxSetCaseRoundTrip() throws {
        let txSet = TransactionSetXDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            txs: []
        )
        let original = StoredTransactionSetXDR.txSet(txSet)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StoredTransactionSetXDR.self, data: encoded)

        guard case .txSet(let decodedTxSet) = decoded else {
            XCTFail("Expected .txSet case"); return
        }
        XCTAssertEqual(decodedTxSet.previousLedgerHash, XDRTestHelpers.wrappedData32())
    }

    func testStoredTransactionSetGeneralizedCaseRoundTrip() throws {
        let v1TxSet = TransactionSetV1XDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            phases: []
        )
        let original = StoredTransactionSetXDR.generalizedTxSet(
            GeneralizedTransactionSetXDR.v1TxSet(v1TxSet)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StoredTransactionSetXDR.self, data: encoded)

        guard case .generalizedTxSet(let genTxSet) = decoded else {
            XCTFail("Expected .generalizedTxSet case"); return
        }
        guard case .v1TxSet(let decodedV1) = genTxSet else {
            XCTFail("Expected .v1TxSet"); return
        }
        XCTAssertEqual(decodedV1.previousLedgerHash, XDRTestHelpers.wrappedData32())
    }

    // MARK: - StoredDebugTransactionSetXDR

    func testStoredDebugTransactionSetRoundTrip() throws {
        let txSet = StoredTransactionSetXDR.txSet(
            TransactionSetXDR(
                previousLedgerHash: XDRTestHelpers.wrappedData32(),
                txs: []
            )
        )
        let stellarValue = StellarValueXDR(
            txSetHash: XDRTestHelpers.wrappedData32(),
            closeTime: 1234567890,
            upgrades: [],
            ext: .basic
        )
        let original = StoredDebugTransactionSetXDR(
            txSet: txSet,
            ledgerSeq: 42,
            scpValue: stellarValue
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StoredDebugTransactionSetXDR.self, data: encoded)

        XCTAssertEqual(decoded.ledgerSeq, 42)
        XCTAssertEqual(decoded.scpValue.closeTime, 1234567890)
        XCTAssertEqual(decoded.scpValue.txSetHash, XDRTestHelpers.wrappedData32())
    }

    // MARK: - PersistedSCPStateV0XDR

    func testPersistedSCPStateV0EmptyRoundTrip() throws {
        let original = PersistedSCPStateV0XDR(
            scpEnvelopes: [],
            quorumSets: [],
            txSets: []
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PersistedSCPStateV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.scpEnvelopes.count, 0)
        XCTAssertEqual(decoded.quorumSets.count, 0)
        XCTAssertEqual(decoded.txSets.count, 0)
    }

    func testPersistedSCPStateV0WithDataRoundTrip() throws {
        let quorumSet = SCPQuorumSetXDR(
            threshold: 2,
            validators: [try XDRTestHelpers.publicKey()],
            innerSets: []
        )
        let txSet = StoredTransactionSetXDR.txSet(
            TransactionSetXDR(
                previousLedgerHash: XDRTestHelpers.wrappedData32(),
                txs: []
            )
        )
        let original = PersistedSCPStateV0XDR(
            scpEnvelopes: [],
            quorumSets: [quorumSet],
            txSets: [txSet]
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PersistedSCPStateV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.quorumSets.count, 1)
        XCTAssertEqual(decoded.quorumSets[0].threshold, 2)
        XCTAssertEqual(decoded.txSets.count, 1)
    }

    // MARK: - PersistedSCPStateV1XDR

    func testPersistedSCPStateV1EmptyRoundTrip() throws {
        let original = PersistedSCPStateV1XDR(
            scpEnvelopes: [],
            quorumSets: []
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PersistedSCPStateV1XDR.self, data: encoded)

        XCTAssertEqual(decoded.scpEnvelopes.count, 0)
        XCTAssertEqual(decoded.quorumSets.count, 0)
    }

    func testPersistedSCPStateV1WithQuorumSetRoundTrip() throws {
        let quorumSet = SCPQuorumSetXDR(
            threshold: 3,
            validators: [try XDRTestHelpers.publicKey()],
            innerSets: []
        )
        let original = PersistedSCPStateV1XDR(
            scpEnvelopes: [],
            quorumSets: [quorumSet]
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PersistedSCPStateV1XDR.self, data: encoded)

        XCTAssertEqual(decoded.quorumSets.count, 1)
        XCTAssertEqual(decoded.quorumSets[0].threshold, 3)
    }

    // MARK: - PersistedSCPStateXDR

    func testPersistedSCPStateV0CaseRoundTrip() throws {
        let v0 = PersistedSCPStateV0XDR(
            scpEnvelopes: [],
            quorumSets: [],
            txSets: []
        )
        let original = PersistedSCPStateXDR.v0(v0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PersistedSCPStateXDR.self, data: encoded)

        guard case .v0(let decodedV0) = decoded else {
            XCTFail("Expected .v0 case"); return
        }
        XCTAssertEqual(decodedV0.scpEnvelopes.count, 0)
        XCTAssertEqual(decodedV0.quorumSets.count, 0)
        XCTAssertEqual(decodedV0.txSets.count, 0)
    }

    func testPersistedSCPStateV1CaseRoundTrip() throws {
        let v1 = PersistedSCPStateV1XDR(
            scpEnvelopes: [],
            quorumSets: []
        )
        let original = PersistedSCPStateXDR.v1(v1)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PersistedSCPStateXDR.self, data: encoded)

        guard case .v1(let decodedV1) = decoded else {
            XCTFail("Expected .v1 case"); return
        }
        XCTAssertEqual(decodedV1.scpEnvelopes.count, 0)
        XCTAssertEqual(decodedV1.quorumSets.count, 0)
    }

    // =========================================================================
    // MARK: - Straggler types: Operations
    // =========================================================================

    // MARK: - AllowTrustOpAssetXDR

    func testAllowTrustOpAssetAlphanum4RoundTrip() throws {
        let original = AllowTrustOpAssetXDR.alphanum4(XDRTestHelpers.wrappedData4())
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AllowTrustOpAssetXDR.self, data: encoded)

        guard case .alphanum4(let code) = decoded else {
            XCTFail("Expected .alphanum4 case"); return
        }
        XCTAssertEqual(code, XDRTestHelpers.wrappedData4())
    }

    func testAllowTrustOpAssetAlphanum12RoundTrip() throws {
        let original = AllowTrustOpAssetXDR.alphanum12(XDRTestHelpers.wrappedData12())
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AllowTrustOpAssetXDR.self, data: encoded)

        guard case .alphanum12(let code) = decoded else {
            XCTFail("Expected .alphanum12 case"); return
        }
        XCTAssertEqual(code, XDRTestHelpers.wrappedData12())
    }

    // MARK: - AllowTrustOperationXDR

    func testAllowTrustOperationRoundTrip() throws {
        let original = AllowTrustOperationXDR(
            trustor: try XDRTestHelpers.publicKey(),
            asset: .alphanum4(XDRTestHelpers.wrappedData4()),
            authorize: 1
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(AllowTrustOperationXDR.self, data: encoded)

        XCTAssertEqual(decoded.authorize, 1)
        guard case .alphanum4(let code) = decoded.asset else {
            XCTFail("Expected .alphanum4 asset"); return
        }
        XCTAssertEqual(code, XDRTestHelpers.wrappedData4())
    }

    // MARK: - CreateAccountOperationXDR

    func testCreateAccountOperationRoundTrip() throws {
        let original = CreateAccountOperationXDR(
            destination: try XDRTestHelpers.publicKey(),
            balance: 100_000_000
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(CreateAccountOperationXDR.self, data: encoded)

        XCTAssertEqual(decoded.startingBalance, 100_000_000)
    }

    // MARK: - PaymentOperationXDR

    func testPaymentOperationRoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = PaymentOperationXDR(
            destination: .ed25519(pk.bytes),
            asset: .native,
            amount: 50_000_000
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PaymentOperationXDR.self, data: encoded)

        XCTAssertEqual(decoded.amount, 50_000_000)
    }

    // MARK: - PathPaymentOperationXDR

    func testPathPaymentOperationRoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let original = PathPaymentOperationXDR(
            sendAsset: .native,
            sendMax: 200_000_000,
            destination: .ed25519(pk.bytes),
            destinationAsset: .native,
            destinationAmount: 100_000_000,
            path: [.native]
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PathPaymentOperationXDR.self, data: encoded)

        XCTAssertEqual(decoded.sendMax, 200_000_000)
        XCTAssertEqual(decoded.destinationAmount, 100_000_000)
        XCTAssertEqual(decoded.path.count, 1)
    }

    // MARK: - ManageOfferOperationXDR

    func testManageOfferOperationRoundTrip() throws {
        let original = ManageOfferOperationXDR(
            selling: .native,
            buying: .native,
            amount: 500_000_000,
            price: PriceXDR(n: 1, d: 2),
            offerID: 12345
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ManageOfferOperationXDR.self, data: encoded)

        XCTAssertEqual(decoded.amount, 500_000_000)
        XCTAssertEqual(decoded.price.n, 1)
        XCTAssertEqual(decoded.price.d, 2)
        XCTAssertEqual(decoded.offerID, 12345)
    }

    // MARK: - CreatePassiveOfferOperationXDR

    func testCreatePassiveOfferOperationRoundTrip() throws {
        let original = CreatePassiveOfferOperationXDR(
            selling: .native,
            buying: .native,
            amount: 300_000_000,
            price: PriceXDR(n: 3, d: 7)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(CreatePassiveOfferOperationXDR.self, data: encoded)

        XCTAssertEqual(decoded.amount, 300_000_000)
        XCTAssertEqual(decoded.price.n, 3)
        XCTAssertEqual(decoded.price.d, 7)
    }

    // MARK: - ChangeTrustOperationXDR

    func testChangeTrustOperationNativeRoundTrip() throws {
        let original = ChangeTrustOperationXDR(
            asset: .native,
            limit: 999_999_999
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ChangeTrustOperationXDR.self, data: encoded)

        XCTAssertEqual(decoded.limit, 999_999_999)
    }

    func testChangeTrustOperationPoolShareRoundTrip() throws {
        let params = LiquidityPoolConstantProductParametersXDR(
            assetA: .native,
            assetB: .native,
            fee: 30
        )
        let original = ChangeTrustOperationXDR(
            asset: .poolShare(.constantProduct(params)),
            limit: Int64.max
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ChangeTrustOperationXDR.self, data: encoded)

        XCTAssertEqual(decoded.limit, Int64.max)
        guard case .poolShare(let pool) = decoded.asset else {
            XCTFail("Expected .poolShare case"); return
        }
        guard case .constantProduct(let decodedParams) = pool else {
            XCTFail("Expected .constantProduct"); return
        }
        XCTAssertEqual(decodedParams.fee, 30)
    }

    // MARK: - SetOptionsOperationXDR

    func testSetOptionsOperationAllNilRoundTrip() throws {
        let original = SetOptionsOperationXDR()
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SetOptionsOperationXDR.self, data: encoded)

        XCTAssertNil(decoded.inflationDestination)
        XCTAssertNil(decoded.clearFlags)
        XCTAssertNil(decoded.setFlags)
        XCTAssertNil(decoded.masterWeight)
        XCTAssertNil(decoded.lowThreshold)
        XCTAssertNil(decoded.medThreshold)
        XCTAssertNil(decoded.highThreshold)
        XCTAssertNil(decoded.homeDomain)
        XCTAssertNil(decoded.signer)
    }

    func testSetOptionsOperationAllFieldsRoundTrip() throws {
        let pk = try XDRTestHelpers.publicKey()
        let signer = SignerXDR(
            key: .ed25519(XDRTestHelpers.wrappedData32()),
            weight: 5
        )
        let original = SetOptionsOperationXDR(
            inflationDestination: pk,
            clearFlags: 1,
            setFlags: 2,
            masterWeight: 10,
            lowThreshold: 1,
            medThreshold: 5,
            highThreshold: 10,
            homeDomain: "example.com",
            signer: signer
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SetOptionsOperationXDR.self, data: encoded)

        XCTAssertNotNil(decoded.inflationDestination)
        XCTAssertEqual(decoded.clearFlags, 1)
        XCTAssertEqual(decoded.setFlags, 2)
        XCTAssertEqual(decoded.masterWeight, 10)
        XCTAssertEqual(decoded.lowThreshold, 1)
        XCTAssertEqual(decoded.medThreshold, 5)
        XCTAssertEqual(decoded.highThreshold, 10)
        XCTAssertEqual(decoded.homeDomain, "example.com")
        XCTAssertNotNil(decoded.signer)
        XCTAssertEqual(decoded.signer?.weight, 5)
    }

    // =========================================================================
    // MARK: - Straggler types: Transaction extensions
    // =========================================================================

    // MARK: - TransactionExtXDR

    func testTransactionExtVoidRoundTrip() throws {
        let original = TransactionExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionExtXDR.self, data: encoded)

        guard case .void = decoded else {
            XCTFail("Expected .void case"); return
        }
    }

    func testTransactionExtSorobanDataRoundTrip() throws {
        let footprint = LedgerFootprintXDR(readOnly: [], readWrite: [])
        let resources = SorobanResourcesXDR(
            footprint: footprint,
            instructions: 1000,
            diskReadBytes: 2000,
            writeBytes: 3000
        )
        let txData = SorobanTransactionDataXDR(
            ext: .void,
            resources: resources,
            resourceFee: 50000
        )
        let original = TransactionExtXDR.sorobanTransactionData(txData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionExtXDR.self, data: encoded)

        guard case .sorobanTransactionData(let decodedData) = decoded else {
            XCTFail("Expected .sorobanTransactionData case"); return
        }
        XCTAssertEqual(decodedData.resourceFee, 50000)
        XCTAssertEqual(decodedData.resources.instructions, 1000)
        XCTAssertEqual(decodedData.resources.diskReadBytes, 2000)
        XCTAssertEqual(decodedData.resources.writeBytes, 3000)
    }

    // MARK: - TransactionV0XDRExtXDR

    func testTransactionV0ExtVoidRoundTrip() throws {
        let original = TransactionV0XDRExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionV0XDRExtXDR.self, data: encoded)

        guard case .void = decoded else {
            XCTFail("Expected .void case"); return
        }
    }

    // MARK: - FeeBumpTransactionXDRExtXDR

    func testFeeBumpTransactionExtVoidRoundTrip() throws {
        let original = FeeBumpTransactionXDRExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(FeeBumpTransactionXDRExtXDR.self, data: encoded)

        guard case .void = decoded else {
            XCTFail("Expected .void case"); return
        }
    }

    // MARK: - LedgerHeaderExtensionV1XDRExtXDR

    func testLedgerHeaderExtensionV1ExtVoidRoundTrip() throws {
        let original = LedgerHeaderExtensionV1XDRExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerHeaderExtensionV1XDRExtXDR.self, data: encoded)

        guard case .void = decoded else {
            XCTFail("Expected .void case"); return
        }
    }

    // MARK: - LedgerHeaderHistoryEntryXDRExtXDR

    func testLedgerHeaderHistoryEntryExtVoidRoundTrip() throws {
        let original = LedgerHeaderHistoryEntryXDRExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerHeaderHistoryEntryXDRExtXDR.self, data: encoded)

        guard case .void = decoded else {
            XCTFail("Expected .void case"); return
        }
    }

    // MARK: - TransactionHistoryResultEntryXDRExtXDR

    func testTransactionHistoryResultEntryExtVoidRoundTrip() throws {
        let original = TransactionHistoryResultEntryXDRExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionHistoryResultEntryXDRExtXDR.self, data: encoded)

        guard case .void = decoded else {
            XCTFail("Expected .void case"); return
        }
    }

    // =========================================================================
    // MARK: - Straggler types: Trust line extensions
    // =========================================================================

    // MARK: - TrustlineEntryExtensionV2

    func testTrustlineEntryExtensionV2RoundTrip() throws {
        let original = TrustlineEntryExtensionV2(liquidityPoolUseCount: 7)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TrustlineEntryExtensionV2.self, data: encoded)

        XCTAssertEqual(decoded.liquidityPoolUseCount, 7)
    }

    // MARK: - TrustlineEntryExtensionV2ExtXDR

    func testTrustlineEntryExtensionV2ExtVoidRoundTrip() throws {
        let original = TrustlineEntryExtensionV2ExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TrustlineEntryExtensionV2ExtXDR.self, data: encoded)

        guard case .void = decoded else {
            XCTFail("Expected .void case"); return
        }
    }

    // MARK: - TrustlineEntryExtV1XDR

    func testTrustlineEntryExtV1VoidRoundTrip() throws {
        let original = TrustlineEntryExtV1XDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TrustlineEntryExtV1XDR.self, data: encoded)

        guard case .void = decoded else {
            XCTFail("Expected .void case"); return
        }
    }

    func testTrustlineEntryExtV1WithV2RoundTrip() throws {
        let v2 = TrustlineEntryExtensionV2(liquidityPoolUseCount: 11)
        let original = TrustlineEntryExtV1XDR.trustlineEntryExtensionV2(v2)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TrustlineEntryExtV1XDR.self, data: encoded)

        guard case .trustlineEntryExtensionV2(let decodedV2) = decoded else {
            XCTFail("Expected .trustlineEntryExtensionV2 case"); return
        }
        XCTAssertEqual(decodedV2.liquidityPoolUseCount, 11)
    }

    // MARK: - TrustlineEntryExtensionV1

    func testTrustlineEntryExtensionV1RoundTrip() throws {
        let liabilities = LiabilitiesXDR(buying: 1000, selling: 2000)
        let original = TrustlineEntryExtensionV1(
            liabilities: liabilities,
            ext: .void
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TrustlineEntryExtensionV1.self, data: encoded)

        XCTAssertEqual(decoded.liabilities.buying, 1000)
        XCTAssertEqual(decoded.liabilities.selling, 2000)
    }

    func testTrustlineEntryExtensionV1WithV2RoundTrip() throws {
        let liabilities = LiabilitiesXDR(buying: 500, selling: 750)
        let v2 = TrustlineEntryExtensionV2(liquidityPoolUseCount: 3)
        let original = TrustlineEntryExtensionV1(
            liabilities: liabilities,
            ext: .trustlineEntryExtensionV2(v2)
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TrustlineEntryExtensionV1.self, data: encoded)

        XCTAssertEqual(decoded.liabilities.buying, 500)
        XCTAssertEqual(decoded.liabilities.selling, 750)
        guard case .trustlineEntryExtensionV2(let decodedV2) = decoded.ext else {
            XCTFail("Expected .trustlineEntryExtensionV2 ext"); return
        }
        XCTAssertEqual(decodedV2.liquidityPoolUseCount, 3)
    }

    // MARK: - TrustlineEntryExtXDR

    func testTrustlineEntryExtVoidRoundTrip() throws {
        let original = TrustlineEntryExtXDR.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TrustlineEntryExtXDR.self, data: encoded)

        guard case .void = decoded else {
            XCTFail("Expected .void case"); return
        }
    }

    func testTrustlineEntryExtWithV1RoundTrip() throws {
        let liabilities = LiabilitiesXDR(buying: 100, selling: 200)
        let v1 = TrustlineEntryExtensionV1(liabilities: liabilities, ext: .void)
        let original = TrustlineEntryExtXDR.trustlineEntryExtensionV1(v1)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TrustlineEntryExtXDR.self, data: encoded)

        guard case .trustlineEntryExtensionV1(let decodedV1) = decoded else {
            XCTFail("Expected .trustlineEntryExtensionV1 case"); return
        }
        XCTAssertEqual(decodedV1.liabilities.buying, 100)
        XCTAssertEqual(decodedV1.liabilities.selling, 200)
    }

    // =========================================================================
    // MARK: - Straggler types: Muxed / Wrapper structs
    // =========================================================================

    // MARK: - MuxedAccountXDRMed25519XDR

    func testMuxedAccountMed25519RoundTrip() throws {
        let original = MuxedAccountXDRMed25519XDR(
            id: 9876543210,
            ed25519: XDRTestHelpers.wrappedData32()
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(MuxedAccountXDRMed25519XDR.self, data: encoded)

        XCTAssertEqual(decoded.id, 9876543210)
        XCTAssertEqual(decoded.ed25519, XDRTestHelpers.wrappedData32())
    }

    // MARK: - SCMapXDR

    func testSCMapEmptyRoundTrip() throws {
        let original = SCMapXDR(wrapped: [])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCMapXDR.self, data: encoded)

        XCTAssertEqual(decoded.wrapped.count, 0)
    }

    func testSCMapWithEntriesRoundTrip() throws {
        let entry1 = SCMapEntryXDR(key: .symbol("name"), val: .string("test"))
        let entry2 = SCMapEntryXDR(key: .u32(1), val: .u32(100))
        let original = SCMapXDR(wrapped: [entry1, entry2])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCMapXDR.self, data: encoded)

        XCTAssertEqual(decoded.wrapped.count, 2)
    }

    // MARK: - SCVecXDR

    func testSCVecEmptyRoundTrip() throws {
        let original = SCVecXDR(wrapped: [])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCVecXDR.self, data: encoded)

        XCTAssertEqual(decoded.wrapped.count, 0)
    }

    func testSCVecWithValuesRoundTrip() throws {
        let original = SCVecXDR(wrapped: [.u32(1), .u32(2), .u32(3)])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCVecXDR.self, data: encoded)

        XCTAssertEqual(decoded.wrapped.count, 3)
    }

    // MARK: - SorobanAuthorizationEntriesXDR

    func testSorobanAuthorizationEntriesEmptyRoundTrip() throws {
        let original = SorobanAuthorizationEntriesXDR(wrapped: [])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanAuthorizationEntriesXDR.self, data: encoded)

        XCTAssertEqual(decoded.wrapped.count, 0)
    }

    func testSorobanAuthorizationEntriesWithEntryRoundTrip() throws {
        let contractAddress = SCAddressXDR.contract(XDRTestHelpers.wrappedData32())
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: "transfer",
            args: [.u32(42)]
        )
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(invokeArgs),
            subInvocations: []
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount,
            rootInvocation: invocation
        )
        let original = SorobanAuthorizationEntriesXDR(wrapped: [entry])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SorobanAuthorizationEntriesXDR.self, data: encoded)

        XCTAssertEqual(decoded.wrapped.count, 1)
    }
}
