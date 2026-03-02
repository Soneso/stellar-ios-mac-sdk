//
//  XDRLedgerTypesP1UnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Round-trip XDR tests for the first half of Stellar-ledger.x:
/// header types, upgrade types, value types, history types, and transaction set types.
class XDRLedgerTypesP1UnitTests: XCTestCase {

    // MARK: - Enums (Equatable)

    func testStellarValueTypeBasicRoundTrip() throws {
        let original = StellarValueTypeXDR.basic
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarValueTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testStellarValueTypeSignedRoundTrip() throws {
        let original = StellarValueTypeXDR.signed
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarValueTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testLedgerHeaderFlagsTradingRoundTrip() throws {
        let original = LedgerHeaderFlagsXDR.tradingFlag
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerHeaderFlagsXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testLedgerHeaderFlagsDepositRoundTrip() throws {
        let original = LedgerHeaderFlagsXDR.depositFlag
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerHeaderFlagsXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testLedgerHeaderFlagsWithdrawalRoundTrip() throws {
        let original = LedgerHeaderFlagsXDR.withdrawalFlag
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerHeaderFlagsXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testLedgerUpgradeTypeAllCasesRoundTrip() throws {
        let cases: [LedgerUpgradeTypeXDR] = [
            .version, .baseFee, .maxTxSetSize, .baseReserve,
            .flags, .config, .maxSorobanTxSetSize
        ]
        for original in cases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(LedgerUpgradeTypeXDR.self, data: encoded)
            XCTAssertEqual(original, decoded)
        }
    }

    func testTxSetComponentTypeRoundTrip() throws {
        let original = TxSetComponentTypeXDR.txsetCompTxsMaybeDiscountedFee
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TxSetComponentTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testLedgerEntryChangeTypeAllCasesRoundTrip() throws {
        let cases: [LedgerEntryChangeType] = [
            .ledgerEntryCreated, .ledgerEntryUpdated, .ledgerEntryRemoved,
            .ledgerEntryState, .ledgerEntryRestore
        ]
        for original in cases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(LedgerEntryChangeType.self, data: encoded)
            XCTAssertEqual(original, decoded)
        }
    }

    // MARK: - LedgerCloseValueSignatureXDR

    func testLedgerCloseValueSignatureRoundTrip() throws {
        let nodeID = try XDRTestHelpers.publicKey()
        let sig = Data(repeating: 0xAA, count: 64)
        let original = LedgerCloseValueSignatureXDR(nodeID: nodeID, signature: sig)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerCloseValueSignatureXDR.self, data: encoded)

        XCTAssertEqual(decoded.nodeID.accountId, nodeID.accountId)
        XCTAssertEqual(decoded.signature, sig)
    }

    // MARK: - StellarValueXDRExtXDR

    func testStellarValueExtBasicRoundTrip() throws {
        let original = StellarValueXDRExtXDR.basic

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarValueXDRExtXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), StellarValueTypeXDR.basic.rawValue)
    }

    func testStellarValueExtSignedRoundTrip() throws {
        let sig = LedgerCloseValueSignatureXDR(
            nodeID: try XDRTestHelpers.publicKey(),
            signature: Data(repeating: 0xBB, count: 32)
        )
        let original = StellarValueXDRExtXDR.lcValueSignature(sig)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarValueXDRExtXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), StellarValueTypeXDR.signed.rawValue)
        if case .lcValueSignature(let v) = decoded {
            XCTAssertEqual(v.nodeID.accountId, sig.nodeID.accountId)
            XCTAssertEqual(v.signature, sig.signature)
        } else {
            XCTFail("Expected .lcValueSignature")
        }
    }

    // MARK: - StellarValueXDR

    func testStellarValueBasicRoundTrip() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let original = StellarValueXDR(
            txSetHash: hash,
            closeTime: 1700000000,
            upgrades: [],
            ext: .basic
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarValueXDR.self, data: encoded)

        XCTAssertEqual(decoded.txSetHash.wrapped, hash.wrapped)
        XCTAssertEqual(decoded.closeTime, 1700000000)
        XCTAssertEqual(decoded.upgrades.count, 0)
        XCTAssertEqual(decoded.ext.type(), StellarValueTypeXDR.basic.rawValue)
    }

    func testStellarValueWithUpgradesRoundTrip() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let upgrade1 = Data([0x01, 0x02, 0x03])
        let upgrade2 = Data([0xAA, 0xBB, 0xCC, 0xDD])
        let original = StellarValueXDR(
            txSetHash: hash,
            closeTime: 1700000000,
            upgrades: [upgrade1, upgrade2],
            ext: .basic
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarValueXDR.self, data: encoded)

        XCTAssertEqual(decoded.upgrades.count, 2)
        XCTAssertEqual(decoded.upgrades[0], upgrade1)
        XCTAssertEqual(decoded.upgrades[1], upgrade2)
    }

    func testStellarValueWithSignedExtRoundTrip() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let lcSig = LedgerCloseValueSignatureXDR(
            nodeID: try XDRTestHelpers.publicKey(),
            signature: Data(repeating: 0xCC, count: 48)
        )
        let original = StellarValueXDR(
            txSetHash: hash,
            closeTime: 1700100000,
            upgrades: [],
            ext: .lcValueSignature(lcSig)
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StellarValueXDR.self, data: encoded)

        XCTAssertEqual(decoded.closeTime, 1700100000)
        XCTAssertEqual(decoded.ext.type(), StellarValueTypeXDR.signed.rawValue)
        if case .lcValueSignature(let v) = decoded.ext {
            XCTAssertEqual(v.signature, Data(repeating: 0xCC, count: 48))
        } else {
            XCTFail("Expected .lcValueSignature in ext")
        }
    }

    // MARK: - LedgerHeaderExtensionV1XDR

    func testLedgerHeaderExtensionV1RoundTrip() throws {
        let original = LedgerHeaderExtensionV1XDR(flags: 0x3, ext: .void)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerHeaderExtensionV1XDR.self, data: encoded)

        XCTAssertEqual(decoded.flags, 0x3)
        XCTAssertEqual(decoded.ext.type(), 0)
    }

    // MARK: - LedgerHeaderXDRExtXDR

    func testLedgerHeaderExtVoidRoundTrip() throws {
        let original = LedgerHeaderXDRExtXDR.void

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerHeaderXDRExtXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 0)
    }

    func testLedgerHeaderExtV1RoundTrip() throws {
        let v1 = LedgerHeaderExtensionV1XDR(flags: 0x5, ext: .void)
        let original = LedgerHeaderXDRExtXDR.v1(v1)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerHeaderXDRExtXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 1)
        if case .v1(let decodedV1) = decoded {
            XCTAssertEqual(decodedV1.flags, 0x5)
        } else {
            XCTFail("Expected .v1")
        }
    }

    // MARK: - LedgerHeaderXDR

    func testLedgerHeaderRoundTrip() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let scpValue = StellarValueXDR(
            txSetHash: hash,
            closeTime: 1700000000,
            upgrades: [],
            ext: .basic
        )
        let skipList = (0..<4).map { i in
            WrappedData32(Data(repeating: UInt8(i + 1), count: 32))
        }
        let original = LedgerHeaderXDR(
            ledgerVersion: 21,
            previousLedgerHash: WrappedData32(Data(repeating: 0x11, count: 32)),
            scpValue: scpValue,
            txSetResultHash: WrappedData32(Data(repeating: 0x22, count: 32)),
            bucketListHash: WrappedData32(Data(repeating: 0x33, count: 32)),
            ledgerSeq: 500000,
            totalCoins: 100_000_000_000_0000000,
            feePool: 50000,
            inflationSeq: 12,
            idPool: 999999,
            baseFee: 100,
            baseReserve: 5000000,
            maxTxSetSize: 1000,
            skipList: skipList,
            ext: .void
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerHeaderXDR.self, data: encoded)

        XCTAssertEqual(decoded.ledgerVersion, 21)
        XCTAssertEqual(decoded.previousLedgerHash.wrapped, Data(repeating: 0x11, count: 32))
        XCTAssertEqual(decoded.scpValue.closeTime, 1700000000)
        XCTAssertEqual(decoded.txSetResultHash.wrapped, Data(repeating: 0x22, count: 32))
        XCTAssertEqual(decoded.bucketListHash.wrapped, Data(repeating: 0x33, count: 32))
        XCTAssertEqual(decoded.ledgerSeq, 500000)
        XCTAssertEqual(decoded.totalCoins, 100_000_000_000_0000000)
        XCTAssertEqual(decoded.feePool, 50000)
        XCTAssertEqual(decoded.inflationSeq, 12)
        XCTAssertEqual(decoded.idPool, 999999)
        XCTAssertEqual(decoded.baseFee, 100)
        XCTAssertEqual(decoded.baseReserve, 5000000)
        XCTAssertEqual(decoded.maxTxSetSize, 1000)
        XCTAssertEqual(decoded.skipList.count, 4)
        XCTAssertEqual(decoded.skipList[0].wrapped, Data(repeating: 1, count: 32))
        XCTAssertEqual(decoded.skipList[3].wrapped, Data(repeating: 4, count: 32))
        XCTAssertEqual(decoded.ext.type(), 0)
    }

    func testLedgerHeaderWithV1ExtRoundTrip() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let scpValue = StellarValueXDR(
            txSetHash: hash,
            closeTime: 1700000000,
            upgrades: [],
            ext: .basic
        )
        let skipList = (0..<4).map { _ in XDRTestHelpers.wrappedData32() }
        let v1Ext = LedgerHeaderExtensionV1XDR(flags: 0x7, ext: .void)
        let original = LedgerHeaderXDR(
            ledgerVersion: 22,
            previousLedgerHash: hash,
            scpValue: scpValue,
            txSetResultHash: hash,
            bucketListHash: hash,
            ledgerSeq: 600000,
            totalCoins: 50_000_000_0000000,
            feePool: 10000,
            inflationSeq: 5,
            idPool: 123456,
            baseFee: 200,
            baseReserve: 10000000,
            maxTxSetSize: 500,
            skipList: skipList,
            ext: .v1(v1Ext)
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerHeaderXDR.self, data: encoded)

        XCTAssertEqual(decoded.ledgerVersion, 22)
        XCTAssertEqual(decoded.ledgerSeq, 600000)
        XCTAssertEqual(decoded.ext.type(), 1)
        if case .v1(let dv1) = decoded.ext {
            XCTAssertEqual(dv1.flags, 0x7)
        } else {
            XCTFail("Expected .v1 ext")
        }
    }

    // MARK: - LedgerUpgradeXDR

    func testLedgerUpgradeVersionRoundTrip() throws {
        let original = LedgerUpgradeXDR.newLedgerVersion(22)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerUpgradeXDR.self, data: encoded)

        if case .newLedgerVersion(let v) = decoded {
            XCTAssertEqual(v, 22)
        } else {
            XCTFail("Expected .newLedgerVersion")
        }
    }

    func testLedgerUpgradeBaseFeeRoundTrip() throws {
        let original = LedgerUpgradeXDR.newBaseFee(200)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerUpgradeXDR.self, data: encoded)

        if case .newBaseFee(let v) = decoded {
            XCTAssertEqual(v, 200)
        } else {
            XCTFail("Expected .newBaseFee")
        }
    }

    func testLedgerUpgradeMaxTxSetSizeRoundTrip() throws {
        let original = LedgerUpgradeXDR.newMaxTxSetSize(2000)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerUpgradeXDR.self, data: encoded)

        if case .newMaxTxSetSize(let v) = decoded {
            XCTAssertEqual(v, 2000)
        } else {
            XCTFail("Expected .newMaxTxSetSize")
        }
    }

    func testLedgerUpgradeBaseReserveRoundTrip() throws {
        let original = LedgerUpgradeXDR.newBaseReserve(10000000)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerUpgradeXDR.self, data: encoded)

        if case .newBaseReserve(let v) = decoded {
            XCTAssertEqual(v, 10000000)
        } else {
            XCTFail("Expected .newBaseReserve")
        }
    }

    func testLedgerUpgradeFlagsRoundTrip() throws {
        let original = LedgerUpgradeXDR.newFlags(0x5)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerUpgradeXDR.self, data: encoded)

        if case .newFlags(let v) = decoded {
            XCTAssertEqual(v, 0x5)
        } else {
            XCTFail("Expected .newFlags")
        }
    }

    func testLedgerUpgradeConfigRoundTrip() throws {
        let key = ConfigUpgradeSetKeyXDR(
            contractID: XDRTestHelpers.wrappedData32(),
            contentHash: WrappedData32(Data(repeating: 0xAB, count: 32))
        )
        let original = LedgerUpgradeXDR.newConfig(key)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerUpgradeXDR.self, data: encoded)

        if case .newConfig(let v) = decoded {
            XCTAssertEqual(v.contractID.wrapped, key.contractID.wrapped)
            XCTAssertEqual(v.contentHash.wrapped, key.contentHash.wrapped)
        } else {
            XCTFail("Expected .newConfig")
        }
    }

    func testLedgerUpgradeMaxSorobanTxSetSizeRoundTrip() throws {
        let original = LedgerUpgradeXDR.newMaxSorobanTxSetSize(500)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerUpgradeXDR.self, data: encoded)

        if case .newMaxSorobanTxSetSize(let v) = decoded {
            XCTAssertEqual(v, 500)
        } else {
            XCTFail("Expected .newMaxSorobanTxSetSize")
        }
    }

    // MARK: - ConfigUpgradeSetKeyXDR

    func testConfigUpgradeSetKeyRoundTrip() throws {
        let original = ConfigUpgradeSetKeyXDR(
            contractID: WrappedData32(Data(repeating: 0x01, count: 32)),
            contentHash: WrappedData32(Data(repeating: 0x02, count: 32))
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigUpgradeSetKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.contractID.wrapped, Data(repeating: 0x01, count: 32))
        XCTAssertEqual(decoded.contentHash.wrapped, Data(repeating: 0x02, count: 32))
    }

    // MARK: - TransactionSetXDR (empty txs)

    func testTransactionSetEmptyRoundTrip() throws {
        let original = TransactionSetXDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            txs: []
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionSetXDR.self, data: encoded)

        XCTAssertEqual(decoded.previousLedgerHash.wrapped, XDRTestHelpers.wrappedData32().wrapped)
        XCTAssertEqual(decoded.txs.count, 0)
    }

    // MARK: - TxSetComponentXDRTxsMaybeDiscountedFeeXDR

    func testTxSetComponentMaybeDiscountedFeeNoBaseFeeRoundTrip() throws {
        let original = TxSetComponentXDRTxsMaybeDiscountedFeeXDR(baseFee: nil, txs: [])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TxSetComponentXDRTxsMaybeDiscountedFeeXDR.self, data: encoded)

        XCTAssertNil(decoded.baseFee)
        XCTAssertEqual(decoded.txs.count, 0)
    }

    func testTxSetComponentMaybeDiscountedFeeWithBaseFeeRoundTrip() throws {
        let original = TxSetComponentXDRTxsMaybeDiscountedFeeXDR(baseFee: 100, txs: [])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TxSetComponentXDRTxsMaybeDiscountedFeeXDR.self, data: encoded)

        XCTAssertEqual(decoded.baseFee, 100)
        XCTAssertEqual(decoded.txs.count, 0)
    }

    // MARK: - TxSetComponentXDR

    func testTxSetComponentRoundTrip() throws {
        let inner = TxSetComponentXDRTxsMaybeDiscountedFeeXDR(baseFee: 250, txs: [])
        let original = TxSetComponentXDR.txsMaybeDiscountedFee(inner)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TxSetComponentXDR.self, data: encoded)

        if case .txsMaybeDiscountedFee(let v) = decoded {
            XCTAssertEqual(v.baseFee, 250)
            XCTAssertEqual(v.txs.count, 0)
        } else {
            XCTFail("Expected .txsMaybeDiscountedFee")
        }
    }

    // MARK: - ParallelTxsComponentXDR

    func testParallelTxsComponentNoBaseFeeRoundTrip() throws {
        let original = ParallelTxsComponentXDR(baseFee: nil, executionStages: [])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ParallelTxsComponentXDR.self, data: encoded)

        XCTAssertNil(decoded.baseFee)
        XCTAssertEqual(decoded.executionStages.count, 0)
    }

    func testParallelTxsComponentWithBaseFeeRoundTrip() throws {
        let original = ParallelTxsComponentXDR(baseFee: 500, executionStages: [])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ParallelTxsComponentXDR.self, data: encoded)

        XCTAssertEqual(decoded.baseFee, 500)
        XCTAssertEqual(decoded.executionStages.count, 0)
    }

    func testParallelTxsComponentWithStagesRoundTrip() throws {
        let cluster = DependentTxClusterXDR(wrapped: [])
        let stage = ParallelTxExecutionStageXDR(wrapped: [cluster])
        let original = ParallelTxsComponentXDR(baseFee: 300, executionStages: [stage])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ParallelTxsComponentXDR.self, data: encoded)

        XCTAssertEqual(decoded.baseFee, 300)
        XCTAssertEqual(decoded.executionStages.count, 1)
        XCTAssertEqual(decoded.executionStages[0].wrapped.count, 1)
        XCTAssertEqual(decoded.executionStages[0].wrapped[0].wrapped.count, 0)
    }

    // MARK: - TransactionPhaseXDR

    func testTransactionPhaseV0ComponentsRoundTrip() throws {
        let inner = TxSetComponentXDRTxsMaybeDiscountedFeeXDR(baseFee: 100, txs: [])
        let component = TxSetComponentXDR.txsMaybeDiscountedFee(inner)
        let original = TransactionPhaseXDR.v0Components([component])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionPhaseXDR.self, data: encoded)

        if case .v0Components(let components) = decoded {
            XCTAssertEqual(components.count, 1)
            if case .txsMaybeDiscountedFee(let v) = components[0] {
                XCTAssertEqual(v.baseFee, 100)
            } else {
                XCTFail("Expected inner .txsMaybeDiscountedFee")
            }
        } else {
            XCTFail("Expected .v0Components")
        }
    }

    func testTransactionPhaseParallelRoundTrip() throws {
        let parallel = ParallelTxsComponentXDR(baseFee: 750, executionStages: [])
        let original = TransactionPhaseXDR.parallelTxsComponent(parallel)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionPhaseXDR.self, data: encoded)

        if case .parallelTxsComponent(let v) = decoded {
            XCTAssertEqual(v.baseFee, 750)
            XCTAssertEqual(v.executionStages.count, 0)
        } else {
            XCTFail("Expected .parallelTxsComponent")
        }
    }

    // MARK: - TransactionSetV1XDR

    func testTransactionSetV1EmptyRoundTrip() throws {
        let original = TransactionSetV1XDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            phases: []
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionSetV1XDR.self, data: encoded)

        XCTAssertEqual(decoded.previousLedgerHash.wrapped, XDRTestHelpers.wrappedData32().wrapped)
        XCTAssertEqual(decoded.phases.count, 0)
    }

    func testTransactionSetV1WithPhasesRoundTrip() throws {
        let inner = TxSetComponentXDRTxsMaybeDiscountedFeeXDR(baseFee: nil, txs: [])
        let component = TxSetComponentXDR.txsMaybeDiscountedFee(inner)
        let phase = TransactionPhaseXDR.v0Components([component])
        let original = TransactionSetV1XDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            phases: [phase]
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionSetV1XDR.self, data: encoded)

        XCTAssertEqual(decoded.phases.count, 1)
    }

    // MARK: - GeneralizedTransactionSetXDR

    func testGeneralizedTransactionSetV1RoundTrip() throws {
        let v1TxSet = TransactionSetV1XDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            phases: []
        )
        let original = GeneralizedTransactionSetXDR.v1TxSet(v1TxSet)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(GeneralizedTransactionSetXDR.self, data: encoded)

        if case .v1TxSet(let v) = decoded {
            XCTAssertEqual(v.previousLedgerHash.wrapped, XDRTestHelpers.wrappedData32().wrapped)
            XCTAssertEqual(v.phases.count, 0)
        } else {
            XCTFail("Expected .v1TxSet")
        }
    }

    // MARK: - TransactionResultPairXDR

    func testTransactionResultPairRoundTrip() throws {
        let txResult = TransactionResultXDR(
            feeCharged: 100,
            result: .tooEarly
        )
        let original = TransactionResultPairXDR(
            transactionHash: XDRTestHelpers.wrappedData32(),
            result: txResult
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionResultPairXDR.self, data: encoded)

        XCTAssertEqual(decoded.transactionHash.wrapped, XDRTestHelpers.wrappedData32().wrapped)
        XCTAssertEqual(decoded.result.feeCharged, 100)
        XCTAssertEqual(decoded.result.code, .tooEarly)
    }

    // MARK: - TransactionResultSetXDR

    func testTransactionResultSetEmptyRoundTrip() throws {
        let original = TransactionResultSetXDR(results: [])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionResultSetXDR.self, data: encoded)

        XCTAssertEqual(decoded.results.count, 0)
    }

    func testTransactionResultSetWithResultsRoundTrip() throws {
        let pair = TransactionResultPairXDR(
            transactionHash: XDRTestHelpers.wrappedData32(),
            result: TransactionResultXDR(feeCharged: 300, result: .badSeq)
        )
        let original = TransactionResultSetXDR(results: [pair])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionResultSetXDR.self, data: encoded)

        XCTAssertEqual(decoded.results.count, 1)
        XCTAssertEqual(decoded.results[0].result.feeCharged, 300)
        XCTAssertEqual(decoded.results[0].result.code, .badSeq)
    }

    // MARK: - LedgerEntryChangeXDR

    func testLedgerEntryChangeRemovedRoundTrip() throws {
        let key = XDRTestHelpers.ledgerKey()
        let original = LedgerEntryChangeXDR.removed(key)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryChangeXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryChangeType.ledgerEntryRemoved.rawValue)
        if case .removed(_) = decoded {
            // success
        } else {
            XCTFail("Expected .removed")
        }
    }

    // MARK: - LedgerEntryChangesXDR

    func testLedgerEntryChangesEmptyRoundTrip() throws {
        let original = LedgerEntryChangesXDR(LedgerEntryChanges: [])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryChangesXDR.self, data: encoded)

        XCTAssertEqual(decoded.ledgerEntryChanges.count, 0)
    }

    func testLedgerEntryChangesWithRemovedRoundTrip() throws {
        let key = XDRTestHelpers.ledgerKey()
        let change = LedgerEntryChangeXDR.removed(key)
        let original = LedgerEntryChangesXDR(LedgerEntryChanges: [change])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerEntryChangesXDR.self, data: encoded)

        XCTAssertEqual(decoded.ledgerEntryChanges.count, 1)
        XCTAssertEqual(decoded.ledgerEntryChanges[0].type(), LedgerEntryChangeType.ledgerEntryRemoved.rawValue)
    }

    // MARK: - UpgradeEntryMetaXDR

    func testUpgradeEntryMetaRoundTrip() throws {
        let upgrade = LedgerUpgradeXDR.newBaseFee(150)
        let changes = LedgerEntryChangesXDR(LedgerEntryChanges: [])
        let original = UpgradeEntryMetaXDR(upgrade: upgrade, changes: changes)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(UpgradeEntryMetaXDR.self, data: encoded)

        if case .newBaseFee(let v) = decoded.upgrade {
            XCTAssertEqual(v, 150)
        } else {
            XCTFail("Expected .newBaseFee")
        }
        XCTAssertEqual(decoded.changes.ledgerEntryChanges.count, 0)
    }

    // MARK: - TransactionHistoryEntryXDRExtXDR

    func testTransactionHistoryEntryExtVoidRoundTrip() throws {
        let original = TransactionHistoryEntryXDRExtXDR.void

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionHistoryEntryXDRExtXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 0)
    }

    func testTransactionHistoryEntryExtGeneralizedTxSetRoundTrip() throws {
        let v1TxSet = TransactionSetV1XDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            phases: []
        )
        let genTxSet = GeneralizedTransactionSetXDR.v1TxSet(v1TxSet)
        let original = TransactionHistoryEntryXDRExtXDR.generalizedTxSet(genTxSet)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionHistoryEntryXDRExtXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), 1)
        if case .generalizedTxSet(let g) = decoded {
            if case .v1TxSet(let v) = g {
                XCTAssertEqual(v.phases.count, 0)
            } else {
                XCTFail("Expected .v1TxSet")
            }
        } else {
            XCTFail("Expected .generalizedTxSet")
        }
    }

    // MARK: - TransactionHistoryEntryXDR

    func testTransactionHistoryEntryRoundTrip() throws {
        let txSet = TransactionSetXDR(
            previousLedgerHash: XDRTestHelpers.wrappedData32(),
            txs: []
        )
        let original = TransactionHistoryEntryXDR(
            ledgerSeq: 12345,
            txSet: txSet,
            ext: .void
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionHistoryEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.ledgerSeq, 12345)
        XCTAssertEqual(decoded.txSet.txs.count, 0)
        XCTAssertEqual(decoded.ext.type(), 0)
    }

    // MARK: - TransactionHistoryResultEntryXDR

    func testTransactionHistoryResultEntryRoundTrip() throws {
        let resultSet = TransactionResultSetXDR(results: [])
        let original = TransactionHistoryResultEntryXDR(
            ledgerSeq: 67890,
            txResultSet: resultSet,
            ext: .void
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(TransactionHistoryResultEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.ledgerSeq, 67890)
        XCTAssertEqual(decoded.txResultSet.results.count, 0)
        XCTAssertEqual(decoded.ext.type(), 0)
    }

    // MARK: - LedgerHeaderHistoryEntryXDR

    func testLedgerHeaderHistoryEntryRoundTrip() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let scpValue = StellarValueXDR(
            txSetHash: hash,
            closeTime: 1700000000,
            upgrades: [],
            ext: .basic
        )
        let skipList = (0..<4).map { _ in XDRTestHelpers.wrappedData32() }
        let header = LedgerHeaderXDR(
            ledgerVersion: 21,
            previousLedgerHash: hash,
            scpValue: scpValue,
            txSetResultHash: hash,
            bucketListHash: hash,
            ledgerSeq: 100,
            totalCoins: 10000000000,
            feePool: 500,
            inflationSeq: 0,
            idPool: 42,
            baseFee: 100,
            baseReserve: 5000000,
            maxTxSetSize: 100,
            skipList: skipList,
            ext: .void
        )
        let original = LedgerHeaderHistoryEntryXDR(
            hash: WrappedData32(Data(repeating: 0xFF, count: 32)),
            header: header,
            ext: .void
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerHeaderHistoryEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.hash.wrapped, Data(repeating: 0xFF, count: 32))
        XCTAssertEqual(decoded.header.ledgerVersion, 21)
        XCTAssertEqual(decoded.header.ledgerSeq, 100)
        XCTAssertEqual(decoded.ext.type(), 0)
    }

    // MARK: - DependentTxClusterXDR

    func testDependentTxClusterEmptyRoundTrip() throws {
        let original = DependentTxClusterXDR(wrapped: [])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(DependentTxClusterXDR.self, data: encoded)

        XCTAssertEqual(decoded.wrapped.count, 0)
    }

    // MARK: - ParallelTxExecutionStageXDR

    func testParallelTxExecutionStageEmptyRoundTrip() throws {
        let original = ParallelTxExecutionStageXDR(wrapped: [])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ParallelTxExecutionStageXDR.self, data: encoded)

        XCTAssertEqual(decoded.wrapped.count, 0)
    }

    func testParallelTxExecutionStageWithClustersRoundTrip() throws {
        let cluster1 = DependentTxClusterXDR(wrapped: [])
        let cluster2 = DependentTxClusterXDR(wrapped: [])
        let original = ParallelTxExecutionStageXDR(wrapped: [cluster1, cluster2])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ParallelTxExecutionStageXDR.self, data: encoded)

        XCTAssertEqual(decoded.wrapped.count, 2)
    }

    // MARK: - SCPBallotXDR

    func testSCPBallotRoundTrip() throws {
        let original = SCPBallotXDR(
            counter: 5,
            value: Data([0x01, 0x02, 0x03])
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPBallotXDR.self, data: encoded)

        XCTAssertEqual(decoded.counter, 5)
        XCTAssertEqual(decoded.value, Data([0x01, 0x02, 0x03]))
    }

    // MARK: - SCPQuorumSetXDR

    func testSCPQuorumSetRoundTrip() throws {
        let validator = try XDRTestHelpers.publicKey()
        let original = SCPQuorumSetXDR(
            threshold: 2,
            validators: [validator],
            innerSets: []
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPQuorumSetXDR.self, data: encoded)

        XCTAssertEqual(decoded.threshold, 2)
        XCTAssertEqual(decoded.validators.count, 1)
        XCTAssertEqual(decoded.validators[0].accountId, validator.accountId)
        XCTAssertEqual(decoded.innerSets.count, 0)
    }

    // MARK: - LedgerSCPMessagesXDR

    func testLedgerSCPMessagesEmptyRoundTrip() throws {
        let original = LedgerSCPMessagesXDR(ledgerSeq: 42, messages: [])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(LedgerSCPMessagesXDR.self, data: encoded)

        XCTAssertEqual(decoded.ledgerSeq, 42)
        XCTAssertEqual(decoded.messages.count, 0)
    }

    // MARK: - SCPHistoryEntryV0XDR

    func testSCPHistoryEntryV0RoundTrip() throws {
        let ledgerMessages = LedgerSCPMessagesXDR(ledgerSeq: 100, messages: [])
        let original = SCPHistoryEntryV0XDR(
            quorumSets: [],
            ledgerMessages: ledgerMessages
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPHistoryEntryV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.quorumSets.count, 0)
        XCTAssertEqual(decoded.ledgerMessages.ledgerSeq, 100)
        XCTAssertEqual(decoded.ledgerMessages.messages.count, 0)
    }

    func testSCPHistoryEntryV0WithQuorumSetRoundTrip() throws {
        let validator = try XDRTestHelpers.publicKey()
        let qSet = SCPQuorumSetXDR(threshold: 1, validators: [validator], innerSets: [])
        let ledgerMessages = LedgerSCPMessagesXDR(ledgerSeq: 200, messages: [])
        let original = SCPHistoryEntryV0XDR(
            quorumSets: [qSet],
            ledgerMessages: ledgerMessages
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPHistoryEntryV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.quorumSets.count, 1)
        XCTAssertEqual(decoded.quorumSets[0].threshold, 1)
        XCTAssertEqual(decoded.quorumSets[0].validators.count, 1)
        XCTAssertEqual(decoded.ledgerMessages.ledgerSeq, 200)
    }

    // MARK: - SCPHistoryEntryXDR

    func testSCPHistoryEntryRoundTrip() throws {
        let ledgerMessages = LedgerSCPMessagesXDR(ledgerSeq: 300, messages: [])
        let v0 = SCPHistoryEntryV0XDR(quorumSets: [], ledgerMessages: ledgerMessages)
        let original = SCPHistoryEntryXDR.v0(v0)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCPHistoryEntryXDR.self, data: encoded)

        if case .v0(let dv0) = decoded {
            XCTAssertEqual(dv0.ledgerMessages.ledgerSeq, 300)
        } else {
            XCTFail("Expected .v0")
        }
    }

    // MARK: - ConfigUpgradeSetXDR

    func testConfigUpgradeSetEmptyRoundTrip() throws {
        let original = ConfigUpgradeSetXDR(updatedEntry: [])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigUpgradeSetXDR.self, data: encoded)

        XCTAssertEqual(decoded.updatedEntry.count, 0)
    }
}
