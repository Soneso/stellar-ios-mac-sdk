//
//  LedgerEntryDataXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class LedgerEntryDataXDRUnitTests: XCTestCase {

    // MARK: - LedgerEntryDataXDR Tests

    func testLedgerEntryDataXDRAccountCase() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let thresholds = WrappedData4(Data([1, 2, 3, 4]))

        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: 1000000,
            sequenceNumber: 1,
            numSubEntries: 0,
            homeDomain: "example.com",
            flags: 0,
            thresholds: thresholds,
            signers: []
        )

        let ledgerData = LedgerEntryDataXDR.account(accountEntry)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.account.rawValue)
        XCTAssertNotNil(decoded.account)
        XCTAssertNil(decoded.trustline)
        XCTAssertEqual(decoded.account?.balance, 1000000)
    }

    // Trustline, ClaimableBalance, and LiquidityPool don't have public initializers
    // Tests for these would require decoding from XDR bytes or using test fixtures

    func testLedgerEntryDataXDROfferCase() throws {
        let sellerString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let seller = try PublicKey(accountId: sellerString)

        let price = PriceXDR(n: 100, d: 1)

        let offerEntry = OfferEntryXDR(
            sellerID: seller,
            offerID: 12345,
            selling: .native,
            buying: .native,
            amount: 1000000,
            price: price,
            flags: 0
        )

        let ledgerData = LedgerEntryDataXDR.offer(offerEntry)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.offer.rawValue)
        XCTAssertNotNil(decoded.offer)
        XCTAssertNil(decoded.account)
        XCTAssertEqual(decoded.offer?.offerID, 12345)
    }

    func testLedgerEntryDataXDRDataCase() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)

        let dataEntry = DataEntryXDR(
            accountID: publicKey,
            dataName: "test_key",
            dataValue: Data([0x01, 0x02, 0x03])
        )

        let ledgerData = LedgerEntryDataXDR.data(dataEntry)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.data.rawValue)
        XCTAssertNotNil(decoded.data)
        XCTAssertNil(decoded.account)
        XCTAssertEqual(decoded.data?.dataName, "test_key")
    }


    func testLedgerEntryDataXDRContractDataCase() throws {
        let contractAddress = SCAddressXDR.account(try PublicKey(accountId: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"))
        let key = SCValXDR.u32(123)
        let val = SCValXDR.u32(456)

        let contractData = ContractDataEntryXDR(
            ext: .void,
            contract: contractAddress,
            key: key,
            durability: .persistent,
            val: val
        )

        let ledgerData = LedgerEntryDataXDR.contractData(contractData)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.contractData.rawValue)
        XCTAssertNotNil(decoded.contractData)
        XCTAssertNil(decoded.account)

        switch decoded.contractData?.key {
        case .u32(let keyVal):
            XCTAssertEqual(keyVal, 123)
        default:
            XCTFail("Expected u32 key")
        }
    }

    func testLedgerEntryDataXDRContractCodeCase() throws {
        let hash = WrappedData32(Data(repeating: 0xDD, count: 32))
        let code = Data([0x00, 0x61, 0x73, 0x6D])

        let contractCode = ContractCodeEntryXDR(
            ext: .void,
            hash: hash,
            code: code
        )

        let ledgerData = LedgerEntryDataXDR.contractCode(contractCode)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.contractCode.rawValue)
        XCTAssertNotNil(decoded.contractCode)
        XCTAssertNil(decoded.account)
        XCTAssertEqual(decoded.contractCode?.hash.wrapped, hash.wrapped)
    }

    func testLedgerEntryDataXDRConfigSettingCase() throws {
        let configSetting = ConfigSettingEntryXDR.contractMaxSizeBytes(1024000)

        let ledgerData = LedgerEntryDataXDR.configSetting(configSetting)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.configSetting.rawValue)
        XCTAssertNotNil(decoded.configSetting)
        XCTAssertNil(decoded.account)

        switch decoded.configSetting {
        case .contractMaxSizeBytes(let size):
            XCTAssertEqual(size, 1024000)
        default:
            XCTFail("Expected contractMaxSizeBytes")
        }
    }

    func testLedgerEntryDataXDRTTLCase() throws {
        let keyHash = WrappedData32(Data(repeating: 0xFF, count: 32))
        let ttlEntry = TTLEntryXDR(keyHash: keyHash, liveUntilLedgerSeq: 1000000)

        let ledgerData = LedgerEntryDataXDR.ttl(ttlEntry)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.ttl.rawValue)
        XCTAssertNotNil(decoded.ttl)
        XCTAssertNil(decoded.account)
        XCTAssertEqual(decoded.ttl?.liveUntilLedgerSeq, 1000000)
    }

    func testLedgerEntryDataXDRFromBase64() throws {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let thresholds = WrappedData4(Data([1, 2, 3, 4]))

        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: 5000000,
            sequenceNumber: 100,
            numSubEntries: 2,
            homeDomain: "test.org",
            flags: 1,
            thresholds: thresholds,
            signers: []
        )

        let ledgerData = LedgerEntryDataXDR.account(accountEntry)

        let encoded = try XDREncoder.encode(ledgerData)
        let base64 = Data(encoded).base64EncodedString()

        let decoded = try LedgerEntryDataXDR(fromBase64: base64)

        XCTAssertEqual(decoded.type(), LedgerEntryType.account.rawValue)
        XCTAssertNotNil(decoded.account)
    }

    func testLedgerEntryDataXDRAllAccessors() throws {
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

        XCTAssertNotNil(ledgerData.account)
        XCTAssertNil(ledgerData.trustline)
        XCTAssertNil(ledgerData.offer)
        XCTAssertNil(ledgerData.data)
        XCTAssertNil(ledgerData.claimableBalance)
        XCTAssertNil(ledgerData.liquidityPool)
        XCTAssertNil(ledgerData.contractData)
        XCTAssertNil(ledgerData.contractCode)
        XCTAssertNil(ledgerData.configSetting)
        XCTAssertNil(ledgerData.ttl)
    }

    // MARK: - ContractDataEntryXDR Tests

    func testContractDataEntryXDRTemporaryDurability() throws {
        let contractAddress = SCAddressXDR.account(try PublicKey(accountId: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"))
        let key = SCValXDR.u32(789)
        let val = SCValXDR.u32(321)

        let contractData = ContractDataEntryXDR(
            ext: .void,
            contract: contractAddress,
            key: key,
            durability: .temporary,
            val: val
        )

        let encoded = try XDREncoder.encode(contractData)
        let decoded = try XDRDecoder.decode(ContractDataEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.durability, ContractDataDurability.temporary)
    }

    func testContractDataEntryXDRPersistentDurability() throws {
        let contractAddress = SCAddressXDR.account(try PublicKey(accountId: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"))
        let key = SCValXDR.u32(111)
        let val = SCValXDR.u32(222)

        let contractData = ContractDataEntryXDR(
            ext: .void,
            contract: contractAddress,
            key: key,
            durability: .persistent,
            val: val
        )

        let encoded = try XDREncoder.encode(contractData)
        let decoded = try XDRDecoder.decode(ContractDataEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.durability, ContractDataDurability.persistent)
    }

    // MARK: - ContractCodeEntryXDR Tests

    func testContractCodeEntryXDRVoidExt() throws {
        let hash = WrappedData32(Data(repeating: 0xAA, count: 32))
        let code = Data([0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00])

        let contractCode = ContractCodeEntryXDR(
            ext: .void,
            hash: hash,
            code: code
        )

        let encoded = try XDREncoder.encode(contractCode)
        let decoded = try XDRDecoder.decode(ContractCodeEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.hash.wrapped, hash.wrapped)
        XCTAssertEqual(decoded.code, code)

        switch decoded.ext {
        case .void:
            break
        default:
            XCTFail("Expected void extension")
        }
    }

    func testContractCodeEntryXDRV1Ext() throws {
        let hash = WrappedData32(Data(repeating: 0xBB, count: 32))
        let code = Data([0x00, 0x61, 0x73, 0x6D])

        let costInputs = ContractCodeCostInputsXDR(
            ext: .void,
            nInstructions: 1000,
            nFunctions: 10,
            nGlobals: 5,
            nTableEntries: 2,
            nTypes: 8,
            nDataSegments: 3,
            nElemSegments: 1,
            nImports: 4,
            nExports: 6,
            nDataSegmentBytes: 500
        )

        let extV1 = ContractCodeEntryExtV1(ext: .void, costInputs: costInputs)

        let contractCode = ContractCodeEntryXDR(
            ext: .v1(extV1),
            hash: hash,
            code: code
        )

        let encoded = try XDREncoder.encode(contractCode)
        let decoded = try XDRDecoder.decode(ContractCodeEntryXDR.self, data: encoded)

        switch decoded.ext {
        case .v1(let decodedExtV1):
            XCTAssertEqual(decodedExtV1.costInputs.nInstructions, 1000)
            XCTAssertEqual(decodedExtV1.costInputs.nFunctions, 10)
        default:
            XCTFail("Expected v1 extension")
        }
    }

    // MARK: - ContractCodeCostInputsXDR Tests

    func testContractCodeCostInputsXDR() throws {
        let costInputs = ContractCodeCostInputsXDR(
            ext: .void,
            nInstructions: 5000,
            nFunctions: 25,
            nGlobals: 15,
            nTableEntries: 8,
            nTypes: 20,
            nDataSegments: 10,
            nElemSegments: 5,
            nImports: 12,
            nExports: 18,
            nDataSegmentBytes: 2000
        )

        let encoded = try XDREncoder.encode(costInputs)
        let decoded = try XDRDecoder.decode(ContractCodeCostInputsXDR.self, data: encoded)

        XCTAssertEqual(decoded.nInstructions, 5000)
        XCTAssertEqual(decoded.nFunctions, 25)
        XCTAssertEqual(decoded.nGlobals, 15)
        XCTAssertEqual(decoded.nTableEntries, 8)
        XCTAssertEqual(decoded.nTypes, 20)
        XCTAssertEqual(decoded.nDataSegments, 10)
        XCTAssertEqual(decoded.nElemSegments, 5)
        XCTAssertEqual(decoded.nImports, 12)
        XCTAssertEqual(decoded.nExports, 18)
        XCTAssertEqual(decoded.nDataSegmentBytes, 2000)
    }

    // MARK: - ContractCodeEntryExt Tests

    func testContractCodeEntryExtVoid() throws {
        let ext = ContractCodeEntryExt.void

        let encoded = try XDREncoder.encode(ext)
        let decoded = try XDRDecoder.decode(ContractCodeEntryExt.self, data: encoded)

        switch decoded {
        case .void:
            break
        default:
            XCTFail("Expected void case")
        }
    }

    func testContractCodeEntryExtV1() throws {
        let costInputs = ContractCodeCostInputsXDR(
            ext: .void,
            nInstructions: 500,
            nFunctions: 5,
            nGlobals: 3,
            nTableEntries: 1,
            nTypes: 4,
            nDataSegments: 2,
            nElemSegments: 1,
            nImports: 2,
            nExports: 3,
            nDataSegmentBytes: 100
        )

        let extV1 = ContractCodeEntryExtV1(ext: .void, costInputs: costInputs)
        let ext = ContractCodeEntryExt.v1(extV1)

        let encoded = try XDREncoder.encode(ext)
        let decoded = try XDRDecoder.decode(ContractCodeEntryExt.self, data: encoded)

        switch decoded {
        case .v1(let decodedExtV1):
            XCTAssertEqual(decodedExtV1.costInputs.nInstructions, 500)
        default:
            XCTFail("Expected v1 case")
        }
    }

    // MARK: - ConfigSettingEntryXDR Tests

    func testConfigSettingContractMaxSizeBytes() throws {
        let config = ConfigSettingEntryXDR.contractMaxSizeBytes(2048000)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.contractMaxSizeBytes.rawValue)

        switch decoded {
        case .contractMaxSizeBytes(let size):
            XCTAssertEqual(size, 2048000)
        default:
            XCTFail("Expected contractMaxSizeBytes")
        }
    }

    func testConfigSettingContractCompute() throws {
        let compute = ConfigSettingContractComputeV0XDR(
            ledgerMaxInstructions: 100000000,
            txMaxInstructions: 10000000,
            feeRatePerInstructionsIncrement: 1000,
            txMemoryLimit: 41943040
        )

        let config = ConfigSettingEntryXDR.contractCompute(compute)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.contractComputeV0.rawValue)

        switch decoded {
        case .contractCompute(let decodedCompute):
            XCTAssertEqual(decodedCompute.ledgerMaxInstructions, 100000000)
            XCTAssertEqual(decodedCompute.txMaxInstructions, 10000000)
            XCTAssertEqual(decodedCompute.feeRatePerInstructionsIncrement, 1000)
            XCTAssertEqual(decodedCompute.txMemoryLimit, 41943040)
        default:
            XCTFail("Expected contractCompute")
        }
    }

    func testConfigSettingContractLedgerCost() throws {
        let ledgerCost = ConfigSettingContractLedgerCostV0XDR(
            ledgerMaxDiskReadEntries: 1000,
            ledgerMaxDiskReadBytes: 10000000,
            ledgerMaxWriteLedgerEntries: 500,
            ledgerMaxWriteBytes: 5000000,
            txMaxDiskReadEntries: 100,
            txMaxDiskReadBytes: 1000000,
            txMaxWriteLedgerEntries: 50,
            txMaxWriteBytes: 500000,
            feeDiskReadLedgerEntry: 100,
            feeWriteLedgerEntry: 200,
            feeDiskRead1KB: 10,
            sorobanStateTargetSizeBytes: 100000000,
            rentFee1KBSorobanStateSizeLow: 5,
            rentFee1KBSorobanStateSizeHigh: 50,
            sorobanStateRentFeeGrowthFactor: 2
        )

        let config = ConfigSettingEntryXDR.contractLedgerCost(ledgerCost)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.contractLedgerCostV0.rawValue)

        switch decoded {
        case .contractLedgerCost(let decodedCost):
            XCTAssertEqual(decodedCost.ledgerMaxDiskReadEntries, 1000)
            XCTAssertEqual(decodedCost.txMaxDiskReadBytes, 1000000)
        default:
            XCTFail("Expected contractLedgerCost")
        }
    }

    func testConfigSettingContractHistoricalData() throws {
        let historicalData = ConfigSettingContractHistoricalDataV0XDR(feeHistorical1KB: 1000)

        let config = ConfigSettingEntryXDR.contractHistoricalData(historicalData)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.contractHistoricalDataV0.rawValue)

        switch decoded {
        case .contractHistoricalData(let decodedData):
            XCTAssertEqual(decodedData.feeHistorical1KB, 1000)
        default:
            XCTFail("Expected contractHistoricalData")
        }
    }

    func testConfigSettingContractEvents() throws {
        let events = ConfigSettingContractEventsV0XDR(
            txMaxContractEventsSizeBytes: 10000,
            feeContractEvents1KB: 500
        )

        let config = ConfigSettingEntryXDR.contractEvents(events)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.contractEventsV0.rawValue)

        switch decoded {
        case .contractEvents(let decodedEvents):
            XCTAssertEqual(decodedEvents.txMaxContractEventsSizeBytes, 10000)
            XCTAssertEqual(decodedEvents.feeContractEvents1KB, 500)
        default:
            XCTFail("Expected contractEvents")
        }
    }

    func testConfigSettingContractBandwidth() throws {
        let bandwidth = ConfigSettingContractBandwidthV0XDR(
            ledgerMaxTxsSizeBytes: 1000000,
            txMaxSizeBytes: 100000,
            feeTxSize1KB: 100
        )

        let config = ConfigSettingEntryXDR.contractBandwidth(bandwidth)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.contractBandwidthV0.rawValue)

        switch decoded {
        case .contractBandwidth(let decodedBandwidth):
            XCTAssertEqual(decodedBandwidth.ledgerMaxTxsSizeBytes, 1000000)
            XCTAssertEqual(decodedBandwidth.txMaxSizeBytes, 100000)
            XCTAssertEqual(decodedBandwidth.feeTxSize1KB, 100)
        default:
            XCTFail("Expected contractBandwidth")
        }
    }

    func testConfigSettingContractCostParamsCpuInsns() throws {
        let entry1 = ContractCostParamEntryXDR(ext: .void, constTerm: 100, linearTerm: 10)
        let entry2 = ContractCostParamEntryXDR(ext: .void, constTerm: 200, linearTerm: 20)
        let params = ContractCostParamsXDR(entries: [entry1, entry2])

        let config = ConfigSettingEntryXDR.contractCostParamsCpuInsns(params)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.contractCostParamsCpuInstructions.rawValue)

        switch decoded {
        case .contractCostParamsCpuInsns(let decodedParams):
            XCTAssertEqual(decodedParams.entries.count, 2)
            XCTAssertEqual(decodedParams.entries[0].constTerm, 100)
            XCTAssertEqual(decodedParams.entries[1].linearTerm, 20)
        default:
            XCTFail("Expected contractCostParamsCpuInsns")
        }
    }

    func testConfigSettingContractDataKeySizeBytes() throws {
        let config = ConfigSettingEntryXDR.contractDataKeySizeBytes(1024)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.contractDataKeySizeBytes.rawValue)

        switch decoded {
        case .contractDataKeySizeBytes(let size):
            XCTAssertEqual(size, 1024)
        default:
            XCTFail("Expected contractDataKeySizeBytes")
        }
    }

    func testConfigSettingContractDataEntrySizeBytes() throws {
        let config = ConfigSettingEntryXDR.contractDataEntrySizeBytes(65536)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.contractDataEntrySizeBytes.rawValue)

        switch decoded {
        case .contractDataEntrySizeBytes(let size):
            XCTAssertEqual(size, 65536)
        default:
            XCTFail("Expected contractDataEntrySizeBytes")
        }
    }

    func testConfigSettingStateArchivalSettings() throws {
        let archivalSettings = StateArchivalSettingsXDR(
            maxEntryTTL: 6312000,
            minTemporaryTTL: 17280,
            minPersistentTTL: 2073600,
            persistentRentRateDenominator: 2103841,
            tempRentRateDenominator: 4207682,
            maxEntriesToArchive: 100,
            liveSorobanStateSizeWindowSampleSize: 10,
            liveSorobanStateSizeWindowSamplePeriod: 5,
            evictionScanSize: 100000,
            startingEvictionScanLevel: 1
        )

        let config = ConfigSettingEntryXDR.stateArchivalSettings(archivalSettings)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.stateArchival.rawValue)

        switch decoded {
        case .stateArchivalSettings(let decodedSettings):
            XCTAssertEqual(decodedSettings.maxEntryTTL, 6312000)
            XCTAssertEqual(decodedSettings.minTemporaryTTL, 17280)
            XCTAssertEqual(decodedSettings.minPersistentTTL, 2073600)
        default:
            XCTFail("Expected stateArchivalSettings")
        }
    }

    func testConfigSettingContractExecutionLanes() throws {
        let executionLanes = ConfigSettingContractExecutionLanesV0XDR(ledgerMaxTxCount: 100)

        let config = ConfigSettingEntryXDR.contractExecutionLanes(executionLanes)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.contractExecutionLanes.rawValue)

        switch decoded {
        case .contractExecutionLanes(let decodedLanes):
            XCTAssertEqual(decodedLanes.ledgerMaxTxCount, 100)
        default:
            XCTFail("Expected contractExecutionLanes")
        }
    }

    func testConfigSettingLiveSorobanStateSizeWindow() throws {
        let window: [UInt64] = [1000, 2000, 3000, 4000, 5000]

        let config = ConfigSettingEntryXDR.liveSorobanStateSizeWindow(window)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.liveSorobanStateSizeWindow.rawValue)

        switch decoded {
        case .liveSorobanStateSizeWindow(let decodedWindow):
            XCTAssertEqual(decodedWindow.count, 5)
            XCTAssertEqual(decodedWindow[0], 1000)
            XCTAssertEqual(decodedWindow[4], 5000)
        default:
            XCTFail("Expected liveSorobanStateSizeWindow")
        }
    }

    func testConfigSettingEvictionIterator() throws {
        let evictionIterator = EvictionIteratorXDR(
            bucketListLevel: 3,
            isCurrBucket: true,
            bucketFileOffset: 12345678
        )

        let config = ConfigSettingEntryXDR.evictionIterator(evictionIterator)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.evictionIterator.rawValue)

        switch decoded {
        case .evictionIterator(let decodedIterator):
            XCTAssertEqual(decodedIterator.bucketListLevel, 3)
            XCTAssertTrue(decodedIterator.isCurrBucket)
            XCTAssertEqual(decodedIterator.bucketFileOffset, 12345678)
        default:
            XCTFail("Expected evictionIterator")
        }
    }

    func testConfigSettingContractParallelCompute() throws {
        let parallelCompute = ConfigSettingContractParallelComputeV0(ledgerMaxDependentTxClusters: 8)

        let config = ConfigSettingEntryXDR.contractParallelCompute(parallelCompute)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.contractParallelComputeV0.rawValue)

        switch decoded {
        case .contractParallelCompute(let decodedCompute):
            XCTAssertEqual(decodedCompute.ledgerMaxDependentTxClusters, 8)
        default:
            XCTFail("Expected contractParallelCompute")
        }
    }

    func testConfigSettingContractLedgerCostExt() throws {
        let ledgerCostExt = ConfigSettingContractLedgerCostExtV0(
            txMaxFootprintEntries: 40,
            feeWrite1KB: 10000
        )

        let config = ConfigSettingEntryXDR.contractLedgerCostExt(ledgerCostExt)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.contractLedgerCostExtV0.rawValue)

        switch decoded {
        case .contractLedgerCostExt(let decodedExt):
            XCTAssertEqual(decodedExt.txMaxFootprintEntries, 40)
            XCTAssertEqual(decodedExt.feeWrite1KB, 10000)
        default:
            XCTFail("Expected contractLedgerCostExt")
        }
    }

    func testConfigSettingSCPTiming() throws {
        let scpTiming = ConfigSettingSCPTiming(
            ledgerTargetCloseTimeMilliseconds: 5000,
            nominationTimeoutInitialMilliseconds: 1000,
            nominationTimeoutIncrementMilliseconds: 500,
            ballotTimeoutInitialMilliseconds: 1000,
            ballotTimeoutIncrementMilliseconds: 500
        )

        let config = ConfigSettingEntryXDR.contractSCPTiming(scpTiming)

        let encoded = try XDREncoder.encode(config)
        let decoded = try XDRDecoder.decode(ConfigSettingEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ConfigSettingID.scpTiming.rawValue)

        switch decoded {
        case .contractSCPTiming(let decodedTiming):
            XCTAssertEqual(decodedTiming.ledgerTargetCloseTimeMilliseconds, 5000)
            XCTAssertEqual(decodedTiming.nominationTimeoutInitialMilliseconds, 1000)
        default:
            XCTFail("Expected contractSCPTiming")
        }
    }

    // MARK: - StateArchivalSettingsXDR Tests

    func testStateArchivalSettingsXDR() throws {
        let settings = StateArchivalSettingsXDR(
            maxEntryTTL: 5184000,
            minTemporaryTTL: 16,
            minPersistentTTL: 4096,
            persistentRentRateDenominator: 1000000,
            tempRentRateDenominator: 2000000,
            maxEntriesToArchive: 1000,
            liveSorobanStateSizeWindowSampleSize: 100,
            liveSorobanStateSizeWindowSamplePeriod: 10,
            evictionScanSize: 100000,
            startingEvictionScanLevel: 12
        )

        let encoded = try XDREncoder.encode(settings)
        let decoded = try XDRDecoder.decode(StateArchivalSettingsXDR.self, data: encoded)

        XCTAssertEqual(decoded.maxEntryTTL, 5184000)
        XCTAssertEqual(decoded.minTemporaryTTL, 16)
        XCTAssertEqual(decoded.minPersistentTTL, 4096)
        XCTAssertEqual(decoded.persistentRentRateDenominator, 1000000)
        XCTAssertEqual(decoded.tempRentRateDenominator, 2000000)
        XCTAssertEqual(decoded.maxEntriesToArchive, 1000)
        XCTAssertEqual(decoded.liveSorobanStateSizeWindowSampleSize, 100)
        XCTAssertEqual(decoded.liveSorobanStateSizeWindowSamplePeriod, 10)
        XCTAssertEqual(decoded.evictionScanSize, 100000)
        XCTAssertEqual(decoded.startingEvictionScanLevel, 12)
    }

    // MARK: - EvictionIteratorXDR Tests

    func testEvictionIteratorXDR() throws {
        let iterator = EvictionIteratorXDR(
            bucketListLevel: 5,
            isCurrBucket: false,
            bucketFileOffset: 999888777
        )

        let encoded = try XDREncoder.encode(iterator)
        let decoded = try XDRDecoder.decode(EvictionIteratorXDR.self, data: encoded)

        XCTAssertEqual(decoded.bucketListLevel, 5)
        XCTAssertFalse(decoded.isCurrBucket)
        XCTAssertEqual(decoded.bucketFileOffset, 999888777)
    }

    // MARK: - ConfigUpgradeSetKeyXDR Tests

    func testConfigUpgradeSetKeyXDR() throws {
        let contractID = WrappedData32(Data(repeating: 0xEE, count: 32))
        let contentHash = WrappedData32(Data(repeating: 0xFF, count: 32))

        let upgradeKey = ConfigUpgradeSetKeyXDR(contractID: contractID, contentHash: contentHash)

        let encoded = try XDREncoder.encode(upgradeKey)
        let decoded = try XDRDecoder.decode(ConfigUpgradeSetKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.contractID.wrapped, contractID.wrapped)
        XCTAssertEqual(decoded.contentHash.wrapped, contentHash.wrapped)
    }

    // MARK: - ContractCostParamEntryXDR Tests

    func testContractCostParamEntryXDR() throws {
        let entry = ContractCostParamEntryXDR(ext: .void, constTerm: 500, linearTerm: 50)

        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(ContractCostParamEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.constTerm, 500)
        XCTAssertEqual(decoded.linearTerm, 50)
    }

    // MARK: - ContractCostParamsXDR Tests

    func testContractCostParamsXDR() throws {
        let entry1 = ContractCostParamEntryXDR(ext: .void, constTerm: 100, linearTerm: 10)
        let entry2 = ContractCostParamEntryXDR(ext: .void, constTerm: 200, linearTerm: 20)
        let entry3 = ContractCostParamEntryXDR(ext: .void, constTerm: 300, linearTerm: 30)

        let params = ContractCostParamsXDR(entries: [entry1, entry2, entry3])

        let encoded = try XDREncoder.encode(params)
        let decoded = try XDRDecoder.decode(ContractCostParamsXDR.self, data: encoded)

        XCTAssertEqual(decoded.entries.count, 3)
        XCTAssertEqual(decoded.entries[0].constTerm, 100)
        XCTAssertEqual(decoded.entries[1].constTerm, 200)
        XCTAssertEqual(decoded.entries[2].constTerm, 300)
    }

    // MARK: - LedgerEntryDataXDR Extended Tests

    func testLedgerEntryDataXDRContractDataTemporary() throws {
        let contractHash = WrappedData32(Data(repeating: 0xAB, count: 32))
        let contractAddress = SCAddressXDR.contract(contractHash)
        let key = SCValXDR.symbol("temp_key")
        let val = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 999))

        let contractData = ContractDataEntryXDR(
            ext: .void,
            contract: contractAddress,
            key: key,
            durability: .temporary,
            val: val
        )

        let ledgerData = LedgerEntryDataXDR.contractData(contractData)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.contractData.rawValue)
        XCTAssertNotNil(decoded.contractData)
        XCTAssertEqual(decoded.contractData?.durability, ContractDataDurability.temporary)

        switch decoded.contractData?.key {
        case .symbol(let keyStr):
            XCTAssertEqual(keyStr, "temp_key")
        default:
            XCTFail("Expected symbol key")
        }
    }

    func testLedgerEntryDataXDRContractDataPersistent() throws {
        let contractHash = WrappedData32(Data(repeating: 0xCD, count: 32))
        let contractAddress = SCAddressXDR.contract(contractHash)
        let key = SCValXDR.symbol("persist_key")
        let val = SCValXDR.bool(true)

        let contractData = ContractDataEntryXDR(
            ext: .void,
            contract: contractAddress,
            key: key,
            durability: .persistent,
            val: val
        )

        let ledgerData = LedgerEntryDataXDR.contractData(contractData)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.contractData.rawValue)
        XCTAssertNotNil(decoded.contractData)
        XCTAssertEqual(decoded.contractData?.durability, ContractDataDurability.persistent)

        switch decoded.contractData?.val {
        case .bool(let boolVal):
            XCTAssertTrue(boolVal)
        default:
            XCTFail("Expected bool value")
        }
    }

    func testLedgerEntryDataXDRContractCodeWithCostInputs() throws {
        let hash = WrappedData32(Data(repeating: 0xEF, count: 32))
        let code = Data([0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00])

        let costInputs = ContractCodeCostInputsXDR(
            ext: .void,
            nInstructions: 50000,
            nFunctions: 100,
            nGlobals: 25,
            nTableEntries: 10,
            nTypes: 50,
            nDataSegments: 15,
            nElemSegments: 8,
            nImports: 20,
            nExports: 30,
            nDataSegmentBytes: 5000
        )

        let extV1 = ContractCodeEntryExtV1(ext: .void, costInputs: costInputs)

        let contractCode = ContractCodeEntryXDR(
            ext: .v1(extV1),
            hash: hash,
            code: code
        )

        let ledgerData = LedgerEntryDataXDR.contractCode(contractCode)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.contractCode.rawValue)
        XCTAssertNotNil(decoded.contractCode)
        XCTAssertEqual(decoded.contractCode?.hash.wrapped, hash.wrapped)
        XCTAssertEqual(decoded.contractCode?.code, code)

        switch decoded.contractCode?.ext {
        case .v1(let decodedExtV1):
            XCTAssertEqual(decodedExtV1.costInputs.nInstructions, 50000)
            XCTAssertEqual(decodedExtV1.costInputs.nFunctions, 100)
            XCTAssertEqual(decodedExtV1.costInputs.nGlobals, 25)
            XCTAssertEqual(decodedExtV1.costInputs.nDataSegmentBytes, 5000)
        default:
            XCTFail("Expected v1 extension with cost inputs")
        }
    }

    func testLedgerEntryDataXDRConfigSettingContractMaxSize() throws {
        let configSetting = ConfigSettingEntryXDR.contractMaxSizeBytes(16777216)

        let ledgerData = LedgerEntryDataXDR.configSetting(configSetting)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.configSetting.rawValue)
        XCTAssertNotNil(decoded.configSetting)

        switch decoded.configSetting {
        case .contractMaxSizeBytes(let size):
            XCTAssertEqual(size, 16777216)
        default:
            XCTFail("Expected contractMaxSizeBytes config setting")
        }
    }

    func testLedgerEntryDataXDRConfigSettingContractCompute() throws {
        let compute = ConfigSettingContractComputeV0XDR(
            ledgerMaxInstructions: 500000000,
            txMaxInstructions: 50000000,
            feeRatePerInstructionsIncrement: 2500,
            txMemoryLimit: 67108864
        )

        let configSetting = ConfigSettingEntryXDR.contractCompute(compute)
        let ledgerData = LedgerEntryDataXDR.configSetting(configSetting)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.configSetting.rawValue)
        XCTAssertNotNil(decoded.configSetting)

        switch decoded.configSetting {
        case .contractCompute(let decodedCompute):
            XCTAssertEqual(decodedCompute.ledgerMaxInstructions, 500000000)
            XCTAssertEqual(decodedCompute.txMaxInstructions, 50000000)
            XCTAssertEqual(decodedCompute.feeRatePerInstructionsIncrement, 2500)
            XCTAssertEqual(decodedCompute.txMemoryLimit, 67108864)
        default:
            XCTFail("Expected contractCompute config setting")
        }
    }

    func testLedgerEntryDataXDRConfigSettingContractLedgerCost() throws {
        let ledgerCost = ConfigSettingContractLedgerCostV0XDR(
            ledgerMaxDiskReadEntries: 2000,
            ledgerMaxDiskReadBytes: 20000000,
            ledgerMaxWriteLedgerEntries: 1000,
            ledgerMaxWriteBytes: 10000000,
            txMaxDiskReadEntries: 200,
            txMaxDiskReadBytes: 2000000,
            txMaxWriteLedgerEntries: 100,
            txMaxWriteBytes: 1000000,
            feeDiskReadLedgerEntry: 500,
            feeWriteLedgerEntry: 1000,
            feeDiskRead1KB: 50,
            sorobanStateTargetSizeBytes: 500000000,
            rentFee1KBSorobanStateSizeLow: 10,
            rentFee1KBSorobanStateSizeHigh: 100,
            sorobanStateRentFeeGrowthFactor: 5
        )

        let configSetting = ConfigSettingEntryXDR.contractLedgerCost(ledgerCost)
        let ledgerData = LedgerEntryDataXDR.configSetting(configSetting)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.configSetting.rawValue)
        XCTAssertNotNil(decoded.configSetting)

        switch decoded.configSetting {
        case .contractLedgerCost(let decodedCost):
            XCTAssertEqual(decodedCost.ledgerMaxDiskReadEntries, 2000)
            XCTAssertEqual(decodedCost.ledgerMaxWriteLedgerEntries, 1000)
            XCTAssertEqual(decodedCost.txMaxDiskReadBytes, 2000000)
            XCTAssertEqual(decodedCost.sorobanStateRentFeeGrowthFactor, 5)
        default:
            XCTFail("Expected contractLedgerCost config setting")
        }
    }

    func testLedgerEntryDataXDRConfigSettingContractBandwidth() throws {
        let bandwidth = ConfigSettingContractBandwidthV0XDR(
            ledgerMaxTxsSizeBytes: 5000000,
            txMaxSizeBytes: 500000,
            feeTxSize1KB: 500
        )

        let configSetting = ConfigSettingEntryXDR.contractBandwidth(bandwidth)
        let ledgerData = LedgerEntryDataXDR.configSetting(configSetting)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.configSetting.rawValue)
        XCTAssertNotNil(decoded.configSetting)

        switch decoded.configSetting {
        case .contractBandwidth(let decodedBandwidth):
            XCTAssertEqual(decodedBandwidth.ledgerMaxTxsSizeBytes, 5000000)
            XCTAssertEqual(decodedBandwidth.txMaxSizeBytes, 500000)
            XCTAssertEqual(decodedBandwidth.feeTxSize1KB, 500)
        default:
            XCTFail("Expected contractBandwidth config setting")
        }
    }

    func testLedgerEntryDataXDRConfigSettingStateArchival() throws {
        let archivalSettings = StateArchivalSettingsXDR(
            maxEntryTTL: 12096000,
            minTemporaryTTL: 34560,
            minPersistentTTL: 4147200,
            persistentRentRateDenominator: 4207682,
            tempRentRateDenominator: 8415364,
            maxEntriesToArchive: 200,
            liveSorobanStateSizeWindowSampleSize: 20,
            liveSorobanStateSizeWindowSamplePeriod: 10,
            evictionScanSize: 200000,
            startingEvictionScanLevel: 2
        )

        let configSetting = ConfigSettingEntryXDR.stateArchivalSettings(archivalSettings)
        let ledgerData = LedgerEntryDataXDR.configSetting(configSetting)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.configSetting.rawValue)
        XCTAssertNotNil(decoded.configSetting)

        switch decoded.configSetting {
        case .stateArchivalSettings(let decodedSettings):
            XCTAssertEqual(decodedSettings.maxEntryTTL, 12096000)
            XCTAssertEqual(decodedSettings.minTemporaryTTL, 34560)
            XCTAssertEqual(decodedSettings.minPersistentTTL, 4147200)
            XCTAssertEqual(decodedSettings.maxEntriesToArchive, 200)
            XCTAssertEqual(decodedSettings.startingEvictionScanLevel, 2)
        default:
            XCTFail("Expected stateArchivalSettings config setting")
        }
    }

    func testLedgerEntryDataXDRTTL() throws {
        let keyHash = WrappedData32(Data(repeating: 0x12, count: 32))
        let ttlEntry = TTLEntryXDR(keyHash: keyHash, liveUntilLedgerSeq: 50000000)

        let ledgerData = LedgerEntryDataXDR.ttl(ttlEntry)

        let encoded = try XDREncoder.encode(ledgerData)
        let decoded = try XDRDecoder.decode(LedgerEntryDataXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), LedgerEntryType.ttl.rawValue)
        XCTAssertNotNil(decoded.ttl)
        XCTAssertNil(decoded.account)
        XCTAssertNil(decoded.contractData)
        XCTAssertEqual(decoded.ttl?.liveUntilLedgerSeq, 50000000)
        XCTAssertEqual(decoded.ttl?.keyHash.wrapped, keyHash.wrapped)
    }

    func testLedgerEntryDataXDRTTLRoundTrip() throws {
        let keyHash = WrappedData32(Data(repeating: 0x34, count: 32))
        let ttlEntry = TTLEntryXDR(keyHash: keyHash, liveUntilLedgerSeq: 99999999)

        let ledgerData = LedgerEntryDataXDR.ttl(ttlEntry)

        let encoded = try XDREncoder.encode(ledgerData)
        let base64 = Data(encoded).base64EncodedString()

        let decodedFromBase64 = try LedgerEntryDataXDR(fromBase64: base64)

        XCTAssertEqual(decodedFromBase64.type(), LedgerEntryType.ttl.rawValue)
        XCTAssertNotNil(decodedFromBase64.ttl)
        XCTAssertEqual(decodedFromBase64.ttl?.liveUntilLedgerSeq, 99999999)
        XCTAssertEqual(decodedFromBase64.ttl?.keyHash.wrapped, keyHash.wrapped)

        let reEncoded = try XDREncoder.encode(decodedFromBase64)
        XCTAssertEqual(encoded, reEncoded)
    }

    func testLedgerEntryDataXDRAllDiscriminants() throws {
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
        let accountData = LedgerEntryDataXDR.account(accountEntry)
        XCTAssertEqual(accountData.type(), LedgerEntryType.account.rawValue)

        let price = PriceXDR(n: 1, d: 1)
        let offerEntry = OfferEntryXDR(
            sellerID: publicKey,
            offerID: 1,
            selling: .native,
            buying: .native,
            amount: 1000,
            price: price,
            flags: 0
        )
        let offerData = LedgerEntryDataXDR.offer(offerEntry)
        XCTAssertEqual(offerData.type(), LedgerEntryType.offer.rawValue)

        let dataEntry = DataEntryXDR(
            accountID: publicKey,
            dataName: "test",
            dataValue: Data([0x01])
        )
        let dataData = LedgerEntryDataXDR.data(dataEntry)
        XCTAssertEqual(dataData.type(), LedgerEntryType.data.rawValue)

        let contractAddress = SCAddressXDR.account(publicKey)
        let contractDataEntry = ContractDataEntryXDR(
            ext: .void,
            contract: contractAddress,
            key: SCValXDR.u32(1),
            durability: .temporary,
            val: SCValXDR.u32(2)
        )
        let contractDataData = LedgerEntryDataXDR.contractData(contractDataEntry)
        XCTAssertEqual(contractDataData.type(), LedgerEntryType.contractData.rawValue)

        let hash = WrappedData32(Data(repeating: 0x00, count: 32))
        let contractCodeEntry = ContractCodeEntryXDR(
            ext: .void,
            hash: hash,
            code: Data([0x00])
        )
        let contractCodeData = LedgerEntryDataXDR.contractCode(contractCodeEntry)
        XCTAssertEqual(contractCodeData.type(), LedgerEntryType.contractCode.rawValue)

        let configSettingData = LedgerEntryDataXDR.configSetting(.contractMaxSizeBytes(1024))
        XCTAssertEqual(configSettingData.type(), LedgerEntryType.configSetting.rawValue)

        let ttlEntry = TTLEntryXDR(keyHash: hash, liveUntilLedgerSeq: 1000)
        let ttlData = LedgerEntryDataXDR.ttl(ttlEntry)
        XCTAssertEqual(ttlData.type(), LedgerEntryType.ttl.rawValue)
    }
}
