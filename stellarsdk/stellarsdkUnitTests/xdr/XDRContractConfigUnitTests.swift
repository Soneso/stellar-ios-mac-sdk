//
//  XDRContractConfigUnitTests.swift
//  stellarsdkTests
//
//  Tests for XDR types defined in Stellar-contract-config-setting.x
//

import XCTest
import stellarsdk

class XDRContractConfigUnitTests: XCTestCase {

    // MARK: - ConfigSettingContractExecutionLanesV0XDR

    func testConfigSettingContractExecutionLanesV0RoundTrip() throws {
        let original = ConfigSettingContractExecutionLanesV0XDR(ledgerMaxTxCount: 150)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingContractExecutionLanesV0XDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerMaxTxCount, 150)
    }

    func testConfigSettingContractExecutionLanesV0MaxValue() throws {
        let original = ConfigSettingContractExecutionLanesV0XDR(ledgerMaxTxCount: UInt32.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingContractExecutionLanesV0XDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerMaxTxCount, UInt32.max)
    }

    // MARK: - ConfigSettingContractComputeV0XDR

    func testConfigSettingContractComputeV0RoundTrip() throws {
        let original = ConfigSettingContractComputeV0XDR(
            ledgerMaxInstructions: 100_000_000_000,
            txMaxInstructions: 50_000_000_000,
            feeRatePerInstructionsIncrement: 25,
            txMemoryLimit: 41_943_040
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingContractComputeV0XDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerMaxInstructions, 100_000_000_000)
        XCTAssertEqual(decoded.txMaxInstructions, 50_000_000_000)
        XCTAssertEqual(decoded.feeRatePerInstructionsIncrement, 25)
        XCTAssertEqual(decoded.txMemoryLimit, 41_943_040)
    }

    func testConfigSettingContractComputeV0NegativeFees() throws {
        // Int64 fields can hold negative values; test that they round-trip correctly
        let original = ConfigSettingContractComputeV0XDR(
            ledgerMaxInstructions: -1,
            txMaxInstructions: Int64.min,
            feeRatePerInstructionsIncrement: Int64.max,
            txMemoryLimit: 0
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingContractComputeV0XDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerMaxInstructions, -1)
        XCTAssertEqual(decoded.txMaxInstructions, Int64.min)
        XCTAssertEqual(decoded.feeRatePerInstructionsIncrement, Int64.max)
        XCTAssertEqual(decoded.txMemoryLimit, 0)
    }

    // MARK: - ConfigSettingContractParallelComputeV0

    func testConfigSettingContractParallelComputeV0RoundTrip() throws {
        let original = ConfigSettingContractParallelComputeV0(ledgerMaxDependentTxClusters: 64)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingContractParallelComputeV0.self, data: encoded)
        XCTAssertEqual(decoded.ledgerMaxDependentTxClusters, 64)
    }

    func testConfigSettingContractParallelComputeV0ZeroValue() throws {
        let original = ConfigSettingContractParallelComputeV0(ledgerMaxDependentTxClusters: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingContractParallelComputeV0.self, data: encoded)
        XCTAssertEqual(decoded.ledgerMaxDependentTxClusters, 0)
    }

    // MARK: - ConfigSettingContractLedgerCostV0XDR

    func testConfigSettingContractLedgerCostV0RoundTrip() throws {
        let original = ConfigSettingContractLedgerCostV0XDR(
            ledgerMaxDiskReadEntries: 200,
            ledgerMaxDiskReadBytes: 200_000,
            ledgerMaxWriteLedgerEntries: 100,
            ledgerMaxWriteBytes: 100_000,
            txMaxDiskReadEntries: 40,
            txMaxDiskReadBytes: 40_000,
            txMaxWriteLedgerEntries: 25,
            txMaxWriteBytes: 25_000,
            feeDiskReadLedgerEntry: 6250,
            feeWriteLedgerEntry: 10000,
            feeDiskRead1KB: 6250,
            sorobanStateTargetSizeBytes: 500_000_000,
            rentFee1KBSorobanStateSizeLow: 1000,
            rentFee1KBSorobanStateSizeHigh: 5000,
            sorobanStateRentFeeGrowthFactor: 2000
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingContractLedgerCostV0XDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerMaxDiskReadEntries, 200)
        XCTAssertEqual(decoded.ledgerMaxDiskReadBytes, 200_000)
        XCTAssertEqual(decoded.ledgerMaxWriteLedgerEntries, 100)
        XCTAssertEqual(decoded.ledgerMaxWriteBytes, 100_000)
        XCTAssertEqual(decoded.txMaxDiskReadEntries, 40)
        XCTAssertEqual(decoded.txMaxDiskReadBytes, 40_000)
        XCTAssertEqual(decoded.txMaxWriteLedgerEntries, 25)
        XCTAssertEqual(decoded.txMaxWriteBytes, 25_000)
        XCTAssertEqual(decoded.feeDiskReadLedgerEntry, 6250)
        XCTAssertEqual(decoded.feeWriteLedgerEntry, 10000)
        XCTAssertEqual(decoded.feeDiskRead1KB, 6250)
        XCTAssertEqual(decoded.sorobanStateTargetSizeBytes, 500_000_000)
        XCTAssertEqual(decoded.rentFee1KBSorobanStateSizeLow, 1000)
        XCTAssertEqual(decoded.rentFee1KBSorobanStateSizeHigh, 5000)
        XCTAssertEqual(decoded.sorobanStateRentFeeGrowthFactor, 2000)
    }

    // MARK: - ConfigSettingContractLedgerCostExtV0

    func testConfigSettingContractLedgerCostExtV0RoundTrip() throws {
        let original = ConfigSettingContractLedgerCostExtV0(txMaxFootprintEntries: 256, feeWrite1KB: 12500)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingContractLedgerCostExtV0.self, data: encoded)
        XCTAssertEqual(decoded.txMaxFootprintEntries, 256)
        XCTAssertEqual(decoded.feeWrite1KB, 12500)
    }

    func testConfigSettingContractLedgerCostExtV0LargeValues() throws {
        let original = ConfigSettingContractLedgerCostExtV0(txMaxFootprintEntries: UInt32.max, feeWrite1KB: Int64.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingContractLedgerCostExtV0.self, data: encoded)
        XCTAssertEqual(decoded.txMaxFootprintEntries, UInt32.max)
        XCTAssertEqual(decoded.feeWrite1KB, Int64.max)
    }

    // MARK: - ConfigSettingContractHistoricalDataV0XDR

    func testConfigSettingContractHistoricalDataV0RoundTrip() throws {
        let original = ConfigSettingContractHistoricalDataV0XDR(feeHistorical1KB: 16235)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingContractHistoricalDataV0XDR.self, data: encoded)
        XCTAssertEqual(decoded.feeHistorical1KB, 16235)
    }

    // MARK: - ConfigSettingContractEventsV0XDR

    func testConfigSettingContractEventsV0RoundTrip() throws {
        let original = ConfigSettingContractEventsV0XDR(txMaxContractEventsSizeBytes: 8198, feeContractEvents1KB: 10000)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingContractEventsV0XDR.self, data: encoded)
        XCTAssertEqual(decoded.txMaxContractEventsSizeBytes, 8198)
        XCTAssertEqual(decoded.feeContractEvents1KB, 10000)
    }

    // MARK: - ConfigSettingContractBandwidthV0XDR

    func testConfigSettingContractBandwidthV0RoundTrip() throws {
        let original = ConfigSettingContractBandwidthV0XDR(
            ledgerMaxTxsSizeBytes: 71680,
            txMaxSizeBytes: 71680,
            feeTxSize1KB: 1624
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingContractBandwidthV0XDR.self, data: encoded)
        XCTAssertEqual(decoded.ledgerMaxTxsSizeBytes, 71680)
        XCTAssertEqual(decoded.txMaxSizeBytes, 71680)
        XCTAssertEqual(decoded.feeTxSize1KB, 1624)
    }

    // MARK: - ContractCostType (enum with Equatable)

    func testContractCostTypeFirstCase() throws {
        let original = ContractCostType.wasmInsnExec
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCostType.self, data: encoded)
        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.rawValue, 0)
    }

    func testContractCostTypeLastCase() throws {
        let original = ContractCostType.bls12381FrInv
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCostType.self, data: encoded)
        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.rawValue, 69)
    }

    func testContractCostTypeMiddleCases() throws {
        let cases: [ContractCostType] = [
            .memAlloc, .memCpy, .memCmp,
            .dispatchHostFunction, .visitObject,
            .valSer, .valDeser,
            .computeSha256Hash, .computeEd25519PubKey, .verifyEd25519Sig,
            .vmInstantiation, .vmCachedInstantiation, .invokeVmFunction,
            .computeKeccak256Hash, .decodeEcdsaCurve256Sig, .recoverEcdsaSecp256k1Key,
            .int256AddSub, .int256Mul, .int256Div, .int256Pow, .int256Shift,
            .chaCha20DrawBytes,
            .parseWasmInstructions, .parseWasmFunctions, .parseWasmGlobals,
            .parseWasmTableEntries, .parseWasmTypes, .parseWasmDataSegments,
            .parseWasmElemSegments, .parseWasmImports, .parseWasmExports,
            .parseWasmDataSegmentBytes,
            .instantiateWasmInstructions, .instantiateWasmFunctions, .instantiateWasmGlobals,
            .instantiateWasmTableEntries, .instantiateWasmTypes, .instantiateWasmDataSegments,
            .instantiateWasmElemSegments, .instantiateWasmImports, .instantiateWasmExports,
            .instantiateWasmDataSegmentBytes,
            .sec1DecodePointUncompressed, .verifyEcdsaSecp256r1Sig,
            .bls12381EncodeFp, .bls12381DecodeFp,
            .bls12381G1CheckPointOnCurve, .bls12381G1CheckPointInSubgroup,
            .bls12381G2CheckPointOnCurve, .bls12381G2CheckPointInSubgroup,
            .bls12381G1ProjectiveToAffine, .bls12381G2ProjectiveToAffine,
            .bls12381G1Add, .bls12381G1Mul, .bls12381G1Msm,
            .bls12381MapFpToG1, .bls12381HashToG1,
            .bls12381G2Add, .bls12381G2Mul, .bls12381G2Msm,
            .bls12381MapFp2ToG2, .bls12381HashToG2,
            .bls12381Pairing,
            .bls12381FrFromU256, .bls12381FrToU256,
            .bls12381FrAddSub, .bls12381FrMul, .bls12381FrPow
        ]
        for costType in cases {
            let encoded = try XDREncoder.encode(costType)
            let decoded = try XDRDecoder.decode(ContractCostType.self, data: encoded)
            XCTAssertEqual(costType, decoded, "Failed round-trip for \(costType)")
        }
    }

    // MARK: - ContractCostParamEntryXDR

    func testContractCostParamEntryRoundTrip() throws {
        let original = ContractCostParamEntryXDR(ext: .void, constTerm: 4325, linearTerm: 562)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCostParamEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.constTerm, 4325)
        XCTAssertEqual(decoded.linearTerm, 562)
    }

    func testContractCostParamEntryNegativeValues() throws {
        let original = ContractCostParamEntryXDR(ext: .void, constTerm: -100, linearTerm: -50)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCostParamEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.constTerm, -100)
        XCTAssertEqual(decoded.linearTerm, -50)
    }

    func testContractCostParamEntryLargeValues() throws {
        let original = ContractCostParamEntryXDR(ext: .void, constTerm: Int64.max, linearTerm: Int64.min)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCostParamEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.constTerm, Int64.max)
        XCTAssertEqual(decoded.linearTerm, Int64.min)
    }

    // MARK: - ContractCostParamsXDR (typedef for array)

    func testContractCostParamsRoundTrip() throws {
        let entry1 = ContractCostParamEntryXDR(ext: .void, constTerm: 735, linearTerm: 32)
        let entry2 = ContractCostParamEntryXDR(ext: .void, constTerm: 2048, linearTerm: 0)
        let entry3 = ContractCostParamEntryXDR(ext: .void, constTerm: 512, linearTerm: 128)
        let original = ContractCostParamsXDR(entries: [entry1, entry2, entry3])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCostParamsXDR.self, data: encoded)
        XCTAssertEqual(decoded.entries.count, 3)
        XCTAssertEqual(decoded.entries[0].constTerm, 735)
        XCTAssertEqual(decoded.entries[0].linearTerm, 32)
        XCTAssertEqual(decoded.entries[1].constTerm, 2048)
        XCTAssertEqual(decoded.entries[1].linearTerm, 0)
        XCTAssertEqual(decoded.entries[2].constTerm, 512)
        XCTAssertEqual(decoded.entries[2].linearTerm, 128)
    }

    func testContractCostParamsEmpty() throws {
        let original = ContractCostParamsXDR(entries: [])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractCostParamsXDR.self, data: encoded)
        XCTAssertEqual(decoded.entries.count, 0)
    }

    // MARK: - StateArchivalSettingsXDR

    func testStateArchivalSettingsRoundTrip() throws {
        let original = StateArchivalSettingsXDR(
            maxEntryTTL: 6_312_000,
            minTemporaryTTL: 16,
            minPersistentTTL: 2_073_600,
            persistentRentRateDenominator: 2_103_840,
            tempRentRateDenominator: 4_096,
            maxEntriesToArchive: 100,
            liveSorobanStateSizeWindowSampleSize: 30,
            liveSorobanStateSizeWindowSamplePeriod: 720,
            evictionScanSize: 40_000,
            startingEvictionScanLevel: 7
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StateArchivalSettingsXDR.self, data: encoded)
        XCTAssertEqual(decoded.maxEntryTTL, 6_312_000)
        XCTAssertEqual(decoded.minTemporaryTTL, 16)
        XCTAssertEqual(decoded.minPersistentTTL, 2_073_600)
        XCTAssertEqual(decoded.persistentRentRateDenominator, 2_103_840)
        XCTAssertEqual(decoded.tempRentRateDenominator, 4_096)
        XCTAssertEqual(decoded.maxEntriesToArchive, 100)
        XCTAssertEqual(decoded.liveSorobanStateSizeWindowSampleSize, 30)
        XCTAssertEqual(decoded.liveSorobanStateSizeWindowSamplePeriod, 720)
        XCTAssertEqual(decoded.evictionScanSize, 40_000)
        XCTAssertEqual(decoded.startingEvictionScanLevel, 7)
    }

    func testStateArchivalSettingsMinimalValues() throws {
        let original = StateArchivalSettingsXDR(
            maxEntryTTL: 1,
            minTemporaryTTL: 1,
            minPersistentTTL: 1,
            persistentRentRateDenominator: 1,
            tempRentRateDenominator: 1,
            maxEntriesToArchive: 0,
            liveSorobanStateSizeWindowSampleSize: 1,
            liveSorobanStateSizeWindowSamplePeriod: 1,
            evictionScanSize: 1,
            startingEvictionScanLevel: 0
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(StateArchivalSettingsXDR.self, data: encoded)
        XCTAssertEqual(decoded.maxEntryTTL, 1)
        XCTAssertEqual(decoded.minTemporaryTTL, 1)
        XCTAssertEqual(decoded.minPersistentTTL, 1)
        XCTAssertEqual(decoded.persistentRentRateDenominator, 1)
        XCTAssertEqual(decoded.tempRentRateDenominator, 1)
        XCTAssertEqual(decoded.maxEntriesToArchive, 0)
        XCTAssertEqual(decoded.liveSorobanStateSizeWindowSampleSize, 1)
        XCTAssertEqual(decoded.liveSorobanStateSizeWindowSamplePeriod, 1)
        XCTAssertEqual(decoded.evictionScanSize, 1)
        XCTAssertEqual(decoded.startingEvictionScanLevel, 0)
    }

    // MARK: - EvictionIteratorXDR

    func testEvictionIteratorRoundTrip() throws {
        let original = EvictionIteratorXDR(bucketListLevel: 5, isCurrBucket: true, bucketFileOffset: 123456789)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(EvictionIteratorXDR.self, data: encoded)
        XCTAssertEqual(decoded.bucketListLevel, 5)
        XCTAssertEqual(decoded.isCurrBucket, true)
        XCTAssertEqual(decoded.bucketFileOffset, 123456789)
    }

    func testEvictionIteratorFalseBucket() throws {
        let original = EvictionIteratorXDR(bucketListLevel: 0, isCurrBucket: false, bucketFileOffset: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(EvictionIteratorXDR.self, data: encoded)
        XCTAssertEqual(decoded.bucketListLevel, 0)
        XCTAssertEqual(decoded.isCurrBucket, false)
        XCTAssertEqual(decoded.bucketFileOffset, 0)
    }

    func testEvictionIteratorMaxOffset() throws {
        let original = EvictionIteratorXDR(bucketListLevel: 11, isCurrBucket: true, bucketFileOffset: UInt64.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(EvictionIteratorXDR.self, data: encoded)
        XCTAssertEqual(decoded.bucketListLevel, 11)
        XCTAssertEqual(decoded.isCurrBucket, true)
        XCTAssertEqual(decoded.bucketFileOffset, UInt64.max)
    }

    // MARK: - ConfigSettingSCPTiming

    func testConfigSettingSCPTimingRoundTrip() throws {
        let original = ConfigSettingSCPTiming(
            ledgerTargetCloseTimeMilliseconds: 5000,
            nominationTimeoutInitialMilliseconds: 1000,
            nominationTimeoutIncrementMilliseconds: 500,
            ballotTimeoutInitialMilliseconds: 1000,
            ballotTimeoutIncrementMilliseconds: 500
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingSCPTiming.self, data: encoded)
        XCTAssertEqual(decoded.ledgerTargetCloseTimeMilliseconds, 5000)
        XCTAssertEqual(decoded.nominationTimeoutInitialMilliseconds, 1000)
        XCTAssertEqual(decoded.nominationTimeoutIncrementMilliseconds, 500)
        XCTAssertEqual(decoded.ballotTimeoutInitialMilliseconds, 1000)
        XCTAssertEqual(decoded.ballotTimeoutIncrementMilliseconds, 500)
    }

    func testConfigSettingSCPTimingLargeValues() throws {
        let original = ConfigSettingSCPTiming(
            ledgerTargetCloseTimeMilliseconds: UInt32.max,
            nominationTimeoutInitialMilliseconds: UInt32.max,
            nominationTimeoutIncrementMilliseconds: UInt32.max,
            ballotTimeoutInitialMilliseconds: UInt32.max,
            ballotTimeoutIncrementMilliseconds: UInt32.max
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingSCPTiming.self, data: encoded)
        XCTAssertEqual(decoded.ledgerTargetCloseTimeMilliseconds, UInt32.max)
        XCTAssertEqual(decoded.nominationTimeoutInitialMilliseconds, UInt32.max)
        XCTAssertEqual(decoded.nominationTimeoutIncrementMilliseconds, UInt32.max)
        XCTAssertEqual(decoded.ballotTimeoutInitialMilliseconds, UInt32.max)
        XCTAssertEqual(decoded.ballotTimeoutIncrementMilliseconds, UInt32.max)
    }

    // MARK: - ConfigSettingID (enum with Equatable)

    func testConfigSettingIDAllCases() throws {
        let cases: [(ConfigSettingID, Int32)] = [
            (.contractMaxSizeBytes, 0),
            (.contractComputeV0, 1),
            (.contractLedgerCostV0, 2),
            (.contractHistoricalDataV0, 3),
            (.contractEventsV0, 4),
            (.contractBandwidthV0, 5),
            (.contractCostParamsCpuInstructions, 6),
            (.contractCostParamsMemoryBytes, 7),
            (.contractDataKeySizeBytes, 8),
            (.contractDataEntrySizeBytes, 9),
            (.stateArchival, 10),
            (.contractExecutionLanes, 11),
            (.liveSorobanStateSizeWindow, 12),
            (.evictionIterator, 13),
            (.contractParallelComputeV0, 14),
            (.contractLedgerCostExtV0, 15),
            (.scpTiming, 16),
        ]
        for (settingID, expectedRawValue) in cases {
            let encoded = try XDREncoder.encode(settingID)
            let decoded = try XDRDecoder.decode(ConfigSettingID.self, data: encoded)
            XCTAssertEqual(settingID, decoded, "Failed round-trip for \(settingID)")
            XCTAssertEqual(decoded.rawValue, expectedRawValue, "Wrong raw value for \(settingID)")
        }
    }

    // MARK: - ConfigSettingEntryXDR (union)

    func testConfigSettingEntryContractMaxSizeBytes() throws {
        let original = ConfigSettingEntryXDR.contractMaxSizeBytes(65536)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.contractMaxSizeBytes.rawValue)
        if case .contractMaxSizeBytes(let val) = decoded {
            XCTAssertEqual(val, 65536)
        } else {
            XCTFail("Expected .contractMaxSizeBytes")
        }
    }

    func testConfigSettingEntryContractCompute() throws {
        let compute = ConfigSettingContractComputeV0XDR(
            ledgerMaxInstructions: 200_000_000_000,
            txMaxInstructions: 100_000_000_000,
            feeRatePerInstructionsIncrement: 50,
            txMemoryLimit: 83_886_080
        )
        let original = ConfigSettingEntryXDR.contractCompute(compute)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.contractComputeV0.rawValue)
        if case .contractCompute(let val) = decoded {
            XCTAssertEqual(val.ledgerMaxInstructions, 200_000_000_000)
            XCTAssertEqual(val.txMaxInstructions, 100_000_000_000)
            XCTAssertEqual(val.feeRatePerInstructionsIncrement, 50)
            XCTAssertEqual(val.txMemoryLimit, 83_886_080)
        } else {
            XCTFail("Expected .contractCompute")
        }
    }

    func testConfigSettingEntryContractLedgerCost() throws {
        let ledgerCost = ConfigSettingContractLedgerCostV0XDR(
            ledgerMaxDiskReadEntries: 300,
            ledgerMaxDiskReadBytes: 300_000,
            ledgerMaxWriteLedgerEntries: 150,
            ledgerMaxWriteBytes: 150_000,
            txMaxDiskReadEntries: 60,
            txMaxDiskReadBytes: 60_000,
            txMaxWriteLedgerEntries: 35,
            txMaxWriteBytes: 35_000,
            feeDiskReadLedgerEntry: 7500,
            feeWriteLedgerEntry: 12500,
            feeDiskRead1KB: 7500,
            sorobanStateTargetSizeBytes: 750_000_000,
            rentFee1KBSorobanStateSizeLow: 1500,
            rentFee1KBSorobanStateSizeHigh: 7500,
            sorobanStateRentFeeGrowthFactor: 3000
        )
        let original = ConfigSettingEntryXDR.contractLedgerCost(ledgerCost)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.contractLedgerCostV0.rawValue)
        if case .contractLedgerCost(let val) = decoded {
            XCTAssertEqual(val.ledgerMaxDiskReadEntries, 300)
            XCTAssertEqual(val.ledgerMaxDiskReadBytes, 300_000)
            XCTAssertEqual(val.feeDiskReadLedgerEntry, 7500)
            XCTAssertEqual(val.sorobanStateRentFeeGrowthFactor, 3000)
        } else {
            XCTFail("Expected .contractLedgerCost")
        }
    }

    func testConfigSettingEntryContractHistoricalData() throws {
        let historicalData = ConfigSettingContractHistoricalDataV0XDR(feeHistorical1KB: 32470)
        let original = ConfigSettingEntryXDR.contractHistoricalData(historicalData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.contractHistoricalDataV0.rawValue)
        if case .contractHistoricalData(let val) = decoded {
            XCTAssertEqual(val.feeHistorical1KB, 32470)
        } else {
            XCTFail("Expected .contractHistoricalData")
        }
    }

    func testConfigSettingEntryContractEvents() throws {
        let events = ConfigSettingContractEventsV0XDR(txMaxContractEventsSizeBytes: 16384, feeContractEvents1KB: 20000)
        let original = ConfigSettingEntryXDR.contractEvents(events)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.contractEventsV0.rawValue)
        if case .contractEvents(let val) = decoded {
            XCTAssertEqual(val.txMaxContractEventsSizeBytes, 16384)
            XCTAssertEqual(val.feeContractEvents1KB, 20000)
        } else {
            XCTFail("Expected .contractEvents")
        }
    }

    func testConfigSettingEntryContractBandwidth() throws {
        let bandwidth = ConfigSettingContractBandwidthV0XDR(
            ledgerMaxTxsSizeBytes: 131072,
            txMaxSizeBytes: 131072,
            feeTxSize1KB: 3248
        )
        let original = ConfigSettingEntryXDR.contractBandwidth(bandwidth)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.contractBandwidthV0.rawValue)
        if case .contractBandwidth(let val) = decoded {
            XCTAssertEqual(val.ledgerMaxTxsSizeBytes, 131072)
            XCTAssertEqual(val.txMaxSizeBytes, 131072)
            XCTAssertEqual(val.feeTxSize1KB, 3248)
        } else {
            XCTFail("Expected .contractBandwidth")
        }
    }

    func testConfigSettingEntryContractCostParamsCpuInsns() throws {
        let entry1 = ContractCostParamEntryXDR(ext: .void, constTerm: 4325, linearTerm: 562)
        let entry2 = ContractCostParamEntryXDR(ext: .void, constTerm: 1089, linearTerm: 0)
        let params = ContractCostParamsXDR(entries: [entry1, entry2])
        let original = ConfigSettingEntryXDR.contractCostParamsCpuInsns(params)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.contractCostParamsCpuInstructions.rawValue)
        if case .contractCostParamsCpuInsns(let val) = decoded {
            XCTAssertEqual(val.entries.count, 2)
            XCTAssertEqual(val.entries[0].constTerm, 4325)
            XCTAssertEqual(val.entries[0].linearTerm, 562)
            XCTAssertEqual(val.entries[1].constTerm, 1089)
            XCTAssertEqual(val.entries[1].linearTerm, 0)
        } else {
            XCTFail("Expected .contractCostParamsCpuInsns")
        }
    }

    func testConfigSettingEntryContractCostParamsMemBytes() throws {
        let entry = ContractCostParamEntryXDR(ext: .void, constTerm: 999, linearTerm: 111)
        let params = ContractCostParamsXDR(entries: [entry])
        let original = ConfigSettingEntryXDR.contractCostParamsMemBytes(params)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.contractCostParamsMemoryBytes.rawValue)
        if case .contractCostParamsMemBytes(let val) = decoded {
            XCTAssertEqual(val.entries.count, 1)
            XCTAssertEqual(val.entries[0].constTerm, 999)
            XCTAssertEqual(val.entries[0].linearTerm, 111)
        } else {
            XCTFail("Expected .contractCostParamsMemBytes")
        }
    }

    func testConfigSettingEntryContractDataKeySizeBytes() throws {
        let original = ConfigSettingEntryXDR.contractDataKeySizeBytes(2048)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.contractDataKeySizeBytes.rawValue)
        if case .contractDataKeySizeBytes(let val) = decoded {
            XCTAssertEqual(val, 2048)
        } else {
            XCTFail("Expected .contractDataKeySizeBytes")
        }
    }

    func testConfigSettingEntryContractDataEntrySizeBytes() throws {
        let original = ConfigSettingEntryXDR.contractDataEntrySizeBytes(131072)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.contractDataEntrySizeBytes.rawValue)
        if case .contractDataEntrySizeBytes(let val) = decoded {
            XCTAssertEqual(val, 131072)
        } else {
            XCTFail("Expected .contractDataEntrySizeBytes")
        }
    }

    func testConfigSettingEntryStateArchivalSettings() throws {
        let archival = StateArchivalSettingsXDR(
            maxEntryTTL: 12_614_400,
            minTemporaryTTL: 32,
            minPersistentTTL: 4_147_200,
            persistentRentRateDenominator: 4_207_680,
            tempRentRateDenominator: 8192,
            maxEntriesToArchive: 200,
            liveSorobanStateSizeWindowSampleSize: 60,
            liveSorobanStateSizeWindowSamplePeriod: 1440,
            evictionScanSize: 80_000,
            startingEvictionScanLevel: 10
        )
        let original = ConfigSettingEntryXDR.stateArchivalSettings(archival)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.stateArchival.rawValue)
        if case .stateArchivalSettings(let val) = decoded {
            XCTAssertEqual(val.maxEntryTTL, 12_614_400)
            XCTAssertEqual(val.minTemporaryTTL, 32)
            XCTAssertEqual(val.minPersistentTTL, 4_147_200)
            XCTAssertEqual(val.persistentRentRateDenominator, 4_207_680)
            XCTAssertEqual(val.tempRentRateDenominator, 8192)
            XCTAssertEqual(val.maxEntriesToArchive, 200)
            XCTAssertEqual(val.liveSorobanStateSizeWindowSampleSize, 60)
            XCTAssertEqual(val.liveSorobanStateSizeWindowSamplePeriod, 1440)
            XCTAssertEqual(val.evictionScanSize, 80_000)
            XCTAssertEqual(val.startingEvictionScanLevel, 10)
        } else {
            XCTFail("Expected .stateArchivalSettings")
        }
    }

    func testConfigSettingEntryContractExecutionLanes() throws {
        let lanes = ConfigSettingContractExecutionLanesV0XDR(ledgerMaxTxCount: 250)
        let original = ConfigSettingEntryXDR.contractExecutionLanes(lanes)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.contractExecutionLanes.rawValue)
        if case .contractExecutionLanes(let val) = decoded {
            XCTAssertEqual(val.ledgerMaxTxCount, 250)
        } else {
            XCTFail("Expected .contractExecutionLanes")
        }
    }

    func testConfigSettingEntryLiveSorobanStateSizeWindow() throws {
        let window: [UInt64] = [500_000_000, 510_000_000, 520_000_000, 515_000_000]
        let original = ConfigSettingEntryXDR.liveSorobanStateSizeWindow(window)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.liveSorobanStateSizeWindow.rawValue)
        if case .liveSorobanStateSizeWindow(let val) = decoded {
            XCTAssertEqual(val.count, 4)
            XCTAssertEqual(val[0], 500_000_000)
            XCTAssertEqual(val[1], 510_000_000)
            XCTAssertEqual(val[2], 520_000_000)
            XCTAssertEqual(val[3], 515_000_000)
        } else {
            XCTFail("Expected .liveSorobanStateSizeWindow")
        }
    }

    func testConfigSettingEntryLiveSorobanStateSizeWindowEmpty() throws {
        let original = ConfigSettingEntryXDR.liveSorobanStateSizeWindow([])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.liveSorobanStateSizeWindow.rawValue)
        if case .liveSorobanStateSizeWindow(let val) = decoded {
            XCTAssertEqual(val.count, 0)
        } else {
            XCTFail("Expected .liveSorobanStateSizeWindow")
        }
    }

    func testConfigSettingEntryEvictionIterator() throws {
        let iterator = EvictionIteratorXDR(bucketListLevel: 7, isCurrBucket: false, bucketFileOffset: 987654321)
        let original = ConfigSettingEntryXDR.evictionIterator(iterator)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.evictionIterator.rawValue)
        if case .evictionIterator(let val) = decoded {
            XCTAssertEqual(val.bucketListLevel, 7)
            XCTAssertEqual(val.isCurrBucket, false)
            XCTAssertEqual(val.bucketFileOffset, 987654321)
        } else {
            XCTFail("Expected .evictionIterator")
        }
    }

    func testConfigSettingEntryContractParallelCompute() throws {
        let parallelCompute = ConfigSettingContractParallelComputeV0(ledgerMaxDependentTxClusters: 128)
        let original = ConfigSettingEntryXDR.contractParallelCompute(parallelCompute)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.contractParallelComputeV0.rawValue)
        if case .contractParallelCompute(let val) = decoded {
            XCTAssertEqual(val.ledgerMaxDependentTxClusters, 128)
        } else {
            XCTFail("Expected .contractParallelCompute")
        }
    }

    func testConfigSettingEntryContractLedgerCostExt() throws {
        let costExt = ConfigSettingContractLedgerCostExtV0(txMaxFootprintEntries: 512, feeWrite1KB: 25000)
        let original = ConfigSettingEntryXDR.contractLedgerCostExt(costExt)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.contractLedgerCostExtV0.rawValue)
        if case .contractLedgerCostExt(let val) = decoded {
            XCTAssertEqual(val.txMaxFootprintEntries, 512)
            XCTAssertEqual(val.feeWrite1KB, 25000)
        } else {
            XCTFail("Expected .contractLedgerCostExt")
        }
    }

    func testConfigSettingEntryContractSCPTiming() throws {
        let scpTiming = ConfigSettingSCPTiming(
            ledgerTargetCloseTimeMilliseconds: 6000,
            nominationTimeoutInitialMilliseconds: 2000,
            nominationTimeoutIncrementMilliseconds: 750,
            ballotTimeoutInitialMilliseconds: 2000,
            ballotTimeoutIncrementMilliseconds: 750
        )
        let original = ConfigSettingEntryXDR.contractSCPTiming(scpTiming)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ConfigSettingID.scpTiming.rawValue)
        if case .contractSCPTiming(let val) = decoded {
            XCTAssertEqual(val.ledgerTargetCloseTimeMilliseconds, 6000)
            XCTAssertEqual(val.nominationTimeoutInitialMilliseconds, 2000)
            XCTAssertEqual(val.nominationTimeoutIncrementMilliseconds, 750)
            XCTAssertEqual(val.ballotTimeoutInitialMilliseconds, 2000)
            XCTAssertEqual(val.ballotTimeoutIncrementMilliseconds, 750)
        } else {
            XCTFail("Expected .contractSCPTiming")
        }
    }
}
