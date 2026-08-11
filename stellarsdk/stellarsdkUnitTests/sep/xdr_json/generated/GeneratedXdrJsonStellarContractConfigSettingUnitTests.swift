//
// GENERATED FILE - DO NOT EDIT
//
// This file was produced by tools/xdr-generator/test/emit_json_tests.rb. It exercises
// the SEP-0051 (XDR-JSON) conversions of every type declared in one .x source. To
// regenerate, run:
//
//     make xdr-generate-tests
//
// Any manual edits will be overwritten on the next run.
//

import XCTest
import Foundation
import stellarsdk

final class GeneratedXdrJsonStellarContractConfigSettingUnitTests: XCTestCase {

    func test_ConfigSettingContractBandwidthV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ConfigSettingContractBandwidthV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ConfigSettingContractBandwidthV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ConfigSettingContractBandwidthV0XDR_roundTrip() throws {
        let original: ConfigSettingContractBandwidthV0XDR = ConfigSettingContractBandwidthV0XDR(ledgerMaxTxsSizeBytes: UInt32(42), txMaxSizeBytes: UInt32(42), feeTxSize1KB: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingContractBandwidthV0XDR.fromXdrJson(json)
        let viaValue = try ConfigSettingContractBandwidthV0XDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingContractBandwidthV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingContractBandwidthV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingContractBandwidthV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingContractBandwidthV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingContractBandwidthV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingContractBandwidthV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingContractComputeV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ConfigSettingContractComputeV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ConfigSettingContractComputeV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ConfigSettingContractComputeV0XDR_roundTrip() throws {
        let original: ConfigSettingContractComputeV0XDR = ConfigSettingContractComputeV0XDR(ledgerMaxInstructions: Int64(1234567), txMaxInstructions: Int64(1234567), feeRatePerInstructionsIncrement: Int64(1234567), txMemoryLimit: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingContractComputeV0XDR.fromXdrJson(json)
        let viaValue = try ConfigSettingContractComputeV0XDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingContractComputeV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingContractComputeV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingContractComputeV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingContractComputeV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingContractComputeV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingContractComputeV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingContractEventsV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ConfigSettingContractEventsV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ConfigSettingContractEventsV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ConfigSettingContractEventsV0XDR_roundTrip() throws {
        let original: ConfigSettingContractEventsV0XDR = ConfigSettingContractEventsV0XDR(txMaxContractEventsSizeBytes: UInt32(42), feeContractEvents1KB: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingContractEventsV0XDR.fromXdrJson(json)
        let viaValue = try ConfigSettingContractEventsV0XDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingContractEventsV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingContractEventsV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingContractEventsV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingContractEventsV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingContractEventsV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingContractEventsV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingContractExecutionLanesV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ConfigSettingContractExecutionLanesV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ConfigSettingContractExecutionLanesV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ConfigSettingContractExecutionLanesV0XDR_roundTrip() throws {
        let original: ConfigSettingContractExecutionLanesV0XDR = ConfigSettingContractExecutionLanesV0XDR(ledgerMaxTxCount: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingContractExecutionLanesV0XDR.fromXdrJson(json)
        let viaValue = try ConfigSettingContractExecutionLanesV0XDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingContractExecutionLanesV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingContractExecutionLanesV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingContractExecutionLanesV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingContractExecutionLanesV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingContractExecutionLanesV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingContractExecutionLanesV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingContractHistoricalDataV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ConfigSettingContractHistoricalDataV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ConfigSettingContractHistoricalDataV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ConfigSettingContractHistoricalDataV0XDR_roundTrip() throws {
        let original: ConfigSettingContractHistoricalDataV0XDR = ConfigSettingContractHistoricalDataV0XDR(feeHistorical1KB: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingContractHistoricalDataV0XDR.fromXdrJson(json)
        let viaValue = try ConfigSettingContractHistoricalDataV0XDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingContractHistoricalDataV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingContractHistoricalDataV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingContractHistoricalDataV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingContractHistoricalDataV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingContractHistoricalDataV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingContractHistoricalDataV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingContractLedgerCostExtV0_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ConfigSettingContractLedgerCostExtV0.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ConfigSettingContractLedgerCostExtV0 must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ConfigSettingContractLedgerCostExtV0_roundTrip() throws {
        let original: ConfigSettingContractLedgerCostExtV0 = ConfigSettingContractLedgerCostExtV0(txMaxFootprintEntries: UInt32(42), feeWrite1KB: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingContractLedgerCostExtV0.fromXdrJson(json)
        let viaValue = try ConfigSettingContractLedgerCostExtV0.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingContractLedgerCostExtV0.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingContractLedgerCostExtV0 must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingContractLedgerCostExtV0 must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingContractLedgerCostExtV0 must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingContractLedgerCostExtV0 must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingContractLedgerCostExtV0 must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingContractLedgerCostV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ConfigSettingContractLedgerCostV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ConfigSettingContractLedgerCostV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ConfigSettingContractLedgerCostV0XDR_roundTrip() throws {
        let original: ConfigSettingContractLedgerCostV0XDR = ConfigSettingContractLedgerCostV0XDR(ledgerMaxDiskReadEntries: UInt32(42), ledgerMaxDiskReadBytes: UInt32(42), ledgerMaxWriteLedgerEntries: UInt32(42), ledgerMaxWriteBytes: UInt32(42), txMaxDiskReadEntries: UInt32(42), txMaxDiskReadBytes: UInt32(42), txMaxWriteLedgerEntries: UInt32(42), txMaxWriteBytes: UInt32(42), feeDiskReadLedgerEntry: Int64(1234567), feeWriteLedgerEntry: Int64(1234567), feeDiskRead1KB: Int64(1234567), sorobanStateTargetSizeBytes: Int64(1234567), rentFee1KBSorobanStateSizeLow: Int64(1234567), rentFee1KBSorobanStateSizeHigh: Int64(1234567), sorobanStateRentFeeGrowthFactor: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingContractLedgerCostV0XDR.fromXdrJson(json)
        let viaValue = try ConfigSettingContractLedgerCostV0XDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingContractLedgerCostV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingContractLedgerCostV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingContractLedgerCostV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingContractLedgerCostV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingContractLedgerCostV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingContractLedgerCostV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingContractParallelComputeV0_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ConfigSettingContractParallelComputeV0.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ConfigSettingContractParallelComputeV0 must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ConfigSettingContractParallelComputeV0_roundTrip() throws {
        let original: ConfigSettingContractParallelComputeV0 = ConfigSettingContractParallelComputeV0(ledgerMaxDependentTxClusters: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingContractParallelComputeV0.fromXdrJson(json)
        let viaValue = try ConfigSettingContractParallelComputeV0.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingContractParallelComputeV0.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingContractParallelComputeV0 must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingContractParallelComputeV0 must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingContractParallelComputeV0 must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingContractParallelComputeV0 must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingContractParallelComputeV0 must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_contractBandwidth_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"contract_bandwidth_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.contract_bandwidth_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "contract_bandwidth_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_contractBandwidth_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .contractBandwidth(ConfigSettingContractBandwidthV0XDR(ledgerMaxTxsSizeBytes: UInt32(42), txMaxSizeBytes: UInt32(42), feeTxSize1KB: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_contractCompute_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"contract_compute_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.contract_compute_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "contract_compute_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_contractCompute_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .contractCompute(ConfigSettingContractComputeV0XDR(ledgerMaxInstructions: Int64(1234567), txMaxInstructions: Int64(1234567), feeRatePerInstructionsIncrement: Int64(1234567), txMemoryLimit: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_contractCostParamsCpuInsns_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"contract_cost_params_cpu_instructions\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.contract_cost_params_cpu_instructions: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "contract_cost_params_cpu_instructions",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_contractCostParamsCpuInsns_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .contractCostParamsCpuInsns(ContractCostParamsXDR(entries: [ContractCostParamEntryXDR(ext: .void, constTerm: Int64(1234567), linearTerm: Int64(1234567))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_contractCostParamsMemBytes_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"contract_cost_params_memory_bytes\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.contract_cost_params_memory_bytes: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "contract_cost_params_memory_bytes",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_contractCostParamsMemBytes_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .contractCostParamsMemBytes(ContractCostParamsXDR(entries: [ContractCostParamEntryXDR(ext: .void, constTerm: Int64(1234567), linearTerm: Int64(1234567))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_contractDataEntrySizeBytes_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"contract_data_entry_size_bytes\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.contract_data_entry_size_bytes: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "contract_data_entry_size_bytes",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_contractDataEntrySizeBytes_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .contractDataEntrySizeBytes(UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_contractDataKeySizeBytes_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"contract_data_key_size_bytes\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.contract_data_key_size_bytes: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "contract_data_key_size_bytes",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_contractDataKeySizeBytes_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .contractDataKeySizeBytes(UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_contractEvents_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"contract_events_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.contract_events_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "contract_events_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_contractEvents_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .contractEvents(ConfigSettingContractEventsV0XDR(txMaxContractEventsSizeBytes: UInt32(42), feeContractEvents1KB: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_contractExecutionLanes_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"contract_execution_lanes\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.contract_execution_lanes: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "contract_execution_lanes",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_contractExecutionLanes_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .contractExecutionLanes(ConfigSettingContractExecutionLanesV0XDR(ledgerMaxTxCount: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_contractHistoricalData_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"contract_historical_data_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.contract_historical_data_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "contract_historical_data_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_contractHistoricalData_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .contractHistoricalData(ConfigSettingContractHistoricalDataV0XDR(feeHistorical1KB: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_contractLedgerCostExt_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"contract_ledger_cost_ext_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.contract_ledger_cost_ext_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "contract_ledger_cost_ext_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_contractLedgerCostExt_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .contractLedgerCostExt(ConfigSettingContractLedgerCostExtV0(txMaxFootprintEntries: UInt32(42), feeWrite1KB: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_contractLedgerCost_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"contract_ledger_cost_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.contract_ledger_cost_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "contract_ledger_cost_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_contractLedgerCost_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .contractLedgerCost(ConfigSettingContractLedgerCostV0XDR(ledgerMaxDiskReadEntries: UInt32(42), ledgerMaxDiskReadBytes: UInt32(42), ledgerMaxWriteLedgerEntries: UInt32(42), ledgerMaxWriteBytes: UInt32(42), txMaxDiskReadEntries: UInt32(42), txMaxDiskReadBytes: UInt32(42), txMaxWriteLedgerEntries: UInt32(42), txMaxWriteBytes: UInt32(42), feeDiskReadLedgerEntry: Int64(1234567), feeWriteLedgerEntry: Int64(1234567), feeDiskRead1KB: Int64(1234567), sorobanStateTargetSizeBytes: Int64(1234567), rentFee1KBSorobanStateSizeLow: Int64(1234567), rentFee1KBSorobanStateSizeHigh: Int64(1234567), sorobanStateRentFeeGrowthFactor: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_contractMaxSizeBytes_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"contract_max_size_bytes\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.contract_max_size_bytes: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "contract_max_size_bytes",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_contractMaxSizeBytes_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .contractMaxSizeBytes(UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_contractParallelCompute_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"contract_parallel_compute_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.contract_parallel_compute_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "contract_parallel_compute_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_contractParallelCompute_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .contractParallelCompute(ConfigSettingContractParallelComputeV0(ledgerMaxDependentTxClusters: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_contractSCPTiming_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"scp_timing\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.scp_timing: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "scp_timing",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_contractSCPTiming_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .contractSCPTiming(ConfigSettingSCPTiming(ledgerTargetCloseTimeMilliseconds: UInt32(42), nominationTimeoutInitialMilliseconds: UInt32(42), nominationTimeoutIncrementMilliseconds: UInt32(42), ballotTimeoutInitialMilliseconds: UInt32(42), ballotTimeoutIncrementMilliseconds: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_evictionIterator_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"eviction_iterator\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.eviction_iterator: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "eviction_iterator",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_evictionIterator_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .evictionIterator(EvictionIteratorXDR(bucketListLevel: UInt32(42), isCurrBucket: true, bucketFileOffset: UInt64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_freezeBypassTxsDelta_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"freeze_bypass_txs_delta\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.freeze_bypass_txs_delta: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "freeze_bypass_txs_delta",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_freezeBypassTxsDelta_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .freezeBypassTxsDelta(FreezeBypassTxsDeltaXDR(addTxs: [WrappedData32(Data(repeating: 0xAB, count: 32))], removeTxs: [WrappedData32(Data(repeating: 0xAB, count: 32))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_freezeBypassTxs_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"freeze_bypass_txs\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.freeze_bypass_txs: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "freeze_bypass_txs",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_freezeBypassTxs_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .freezeBypassTxs(FreezeBypassTxsXDR(txHashes: [WrappedData32(Data(repeating: 0xAB, count: 32))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_frozenLedgerKeysDelta_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"frozen_ledger_keys_delta\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.frozen_ledger_keys_delta: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "frozen_ledger_keys_delta",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_frozenLedgerKeysDelta_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .frozenLedgerKeysDelta(FrozenLedgerKeysDeltaXDR(keysToFreeze: [Data([0x01, 0x02, 0x03])], keysToUnfreeze: [Data([0x01, 0x02, 0x03])]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_frozenLedgerKeys_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"frozen_ledger_keys\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.frozen_ledger_keys: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "frozen_ledger_keys",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_frozenLedgerKeys_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .frozenLedgerKeys(FrozenLedgerKeysXDR(keys: [Data([0x01, 0x02, 0x03])]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_liveSorobanStateSizeWindow_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"live_soroban_state_size_window\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.live_soroban_state_size_window: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "live_soroban_state_size_window",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_liveSorobanStateSizeWindow_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .liveSorobanStateSizeWindow([UInt64(1234567)])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingEntryXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ConfigSettingEntryXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ConfigSettingEntryXDR_stateArchivalSettings_rejectsBareString() throws {
        XCTAssertThrowsError(try ConfigSettingEntryXDR.fromXdrJson("\"state_archival\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ConfigSettingEntryXDR.state_archival: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingEntryXDR")
            XCTAssertEqual(key, "state_archival",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ConfigSettingEntryXDR_stateArchivalSettings_roundTrip() throws {
        let original: ConfigSettingEntryXDR = .stateArchivalSettings(StateArchivalSettingsXDR(maxEntryTTL: UInt32(42), minTemporaryTTL: UInt32(42), minPersistentTTL: UInt32(42), persistentRentRateDenominator: Int64(1234567), tempRentRateDenominator: Int64(1234567), maxEntriesToArchive: UInt32(42), liveSorobanStateSizeWindowSampleSize: UInt32(42), liveSorobanStateSizeWindowSamplePeriod: UInt32(42), evictionScanSize: UInt32(42), startingEvictionScanLevel: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingEntryXDR.fromXdrJson(json)
        let viaValue = try ConfigSettingEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_BANDWIDTH_V0() throws {
        let value: ConfigSettingID = .contractBandwidthV0
        XCTAssertEqual(try value.toXdrJson(), "\"contract_bandwidth_v0\"",
                       "ConfigSettingID.contractBandwidthV0 must render as contract_bandwidth_v0")
        XCTAssertEqual(value.rawValue, Int32(5),
                       "ConfigSettingID.contractBandwidthV0 must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"contract_bandwidth_v0\""), value,
                       "contract_bandwidth_v0 must read back as ConfigSettingID.contractBandwidthV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_COMPUTE_V0() throws {
        let value: ConfigSettingID = .contractComputeV0
        XCTAssertEqual(try value.toXdrJson(), "\"contract_compute_v0\"",
                       "ConfigSettingID.contractComputeV0 must render as contract_compute_v0")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "ConfigSettingID.contractComputeV0 must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"contract_compute_v0\""), value,
                       "contract_compute_v0 must read back as ConfigSettingID.contractComputeV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS() throws {
        let value: ConfigSettingID = .contractCostParamsCpuInstructions
        XCTAssertEqual(try value.toXdrJson(), "\"contract_cost_params_cpu_instructions\"",
                       "ConfigSettingID.contractCostParamsCpuInstructions must render as contract_cost_params_cpu_instructions")
        XCTAssertEqual(value.rawValue, Int32(6),
                       "ConfigSettingID.contractCostParamsCpuInstructions must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"contract_cost_params_cpu_instructions\""), value,
                       "contract_cost_params_cpu_instructions must read back as ConfigSettingID.contractCostParamsCpuInstructions")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES() throws {
        let value: ConfigSettingID = .contractCostParamsMemoryBytes
        XCTAssertEqual(try value.toXdrJson(), "\"contract_cost_params_memory_bytes\"",
                       "ConfigSettingID.contractCostParamsMemoryBytes must render as contract_cost_params_memory_bytes")
        XCTAssertEqual(value.rawValue, Int32(7),
                       "ConfigSettingID.contractCostParamsMemoryBytes must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"contract_cost_params_memory_bytes\""), value,
                       "contract_cost_params_memory_bytes must read back as ConfigSettingID.contractCostParamsMemoryBytes")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES() throws {
        let value: ConfigSettingID = .contractDataEntrySizeBytes
        XCTAssertEqual(try value.toXdrJson(), "\"contract_data_entry_size_bytes\"",
                       "ConfigSettingID.contractDataEntrySizeBytes must render as contract_data_entry_size_bytes")
        XCTAssertEqual(value.rawValue, Int32(9),
                       "ConfigSettingID.contractDataEntrySizeBytes must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"contract_data_entry_size_bytes\""), value,
                       "contract_data_entry_size_bytes must read back as ConfigSettingID.contractDataEntrySizeBytes")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES() throws {
        let value: ConfigSettingID = .contractDataKeySizeBytes
        XCTAssertEqual(try value.toXdrJson(), "\"contract_data_key_size_bytes\"",
                       "ConfigSettingID.contractDataKeySizeBytes must render as contract_data_key_size_bytes")
        XCTAssertEqual(value.rawValue, Int32(8),
                       "ConfigSettingID.contractDataKeySizeBytes must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"contract_data_key_size_bytes\""), value,
                       "contract_data_key_size_bytes must read back as ConfigSettingID.contractDataKeySizeBytes")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_EVENTS_V0() throws {
        let value: ConfigSettingID = .contractEventsV0
        XCTAssertEqual(try value.toXdrJson(), "\"contract_events_v0\"",
                       "ConfigSettingID.contractEventsV0 must render as contract_events_v0")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "ConfigSettingID.contractEventsV0 must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"contract_events_v0\""), value,
                       "contract_events_v0 must read back as ConfigSettingID.contractEventsV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_EXECUTION_LANES() throws {
        let value: ConfigSettingID = .contractExecutionLanes
        XCTAssertEqual(try value.toXdrJson(), "\"contract_execution_lanes\"",
                       "ConfigSettingID.contractExecutionLanes must render as contract_execution_lanes")
        XCTAssertEqual(value.rawValue, Int32(11),
                       "ConfigSettingID.contractExecutionLanes must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"contract_execution_lanes\""), value,
                       "contract_execution_lanes must read back as ConfigSettingID.contractExecutionLanes")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0() throws {
        let value: ConfigSettingID = .contractHistoricalDataV0
        XCTAssertEqual(try value.toXdrJson(), "\"contract_historical_data_v0\"",
                       "ConfigSettingID.contractHistoricalDataV0 must render as contract_historical_data_v0")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "ConfigSettingID.contractHistoricalDataV0 must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"contract_historical_data_v0\""), value,
                       "contract_historical_data_v0 must read back as ConfigSettingID.contractHistoricalDataV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0() throws {
        let value: ConfigSettingID = .contractLedgerCostExtV0
        XCTAssertEqual(try value.toXdrJson(), "\"contract_ledger_cost_ext_v0\"",
                       "ConfigSettingID.contractLedgerCostExtV0 must render as contract_ledger_cost_ext_v0")
        XCTAssertEqual(value.rawValue, Int32(15),
                       "ConfigSettingID.contractLedgerCostExtV0 must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"contract_ledger_cost_ext_v0\""), value,
                       "contract_ledger_cost_ext_v0 must read back as ConfigSettingID.contractLedgerCostExtV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_LEDGER_COST_V0() throws {
        let value: ConfigSettingID = .contractLedgerCostV0
        XCTAssertEqual(try value.toXdrJson(), "\"contract_ledger_cost_v0\"",
                       "ConfigSettingID.contractLedgerCostV0 must render as contract_ledger_cost_v0")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "ConfigSettingID.contractLedgerCostV0 must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"contract_ledger_cost_v0\""), value,
                       "contract_ledger_cost_v0 must read back as ConfigSettingID.contractLedgerCostV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES() throws {
        let value: ConfigSettingID = .contractMaxSizeBytes
        XCTAssertEqual(try value.toXdrJson(), "\"contract_max_size_bytes\"",
                       "ConfigSettingID.contractMaxSizeBytes must render as contract_max_size_bytes")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ConfigSettingID.contractMaxSizeBytes must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"contract_max_size_bytes\""), value,
                       "contract_max_size_bytes must read back as ConfigSettingID.contractMaxSizeBytes")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0() throws {
        let value: ConfigSettingID = .contractParallelComputeV0
        XCTAssertEqual(try value.toXdrJson(), "\"contract_parallel_compute_v0\"",
                       "ConfigSettingID.contractParallelComputeV0 must render as contract_parallel_compute_v0")
        XCTAssertEqual(value.rawValue, Int32(14),
                       "ConfigSettingID.contractParallelComputeV0 must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"contract_parallel_compute_v0\""), value,
                       "contract_parallel_compute_v0 must read back as ConfigSettingID.contractParallelComputeV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_EVICTION_ITERATOR() throws {
        let value: ConfigSettingID = .evictionIterator
        XCTAssertEqual(try value.toXdrJson(), "\"eviction_iterator\"",
                       "ConfigSettingID.evictionIterator must render as eviction_iterator")
        XCTAssertEqual(value.rawValue, Int32(13),
                       "ConfigSettingID.evictionIterator must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"eviction_iterator\""), value,
                       "eviction_iterator must read back as ConfigSettingID.evictionIterator")
    }

    func test_ConfigSettingID_CONFIG_SETTING_FREEZE_BYPASS_TXS() throws {
        let value: ConfigSettingID = .freezeBypassTxs
        XCTAssertEqual(try value.toXdrJson(), "\"freeze_bypass_txs\"",
                       "ConfigSettingID.freezeBypassTxs must render as freeze_bypass_txs")
        XCTAssertEqual(value.rawValue, Int32(19),
                       "ConfigSettingID.freezeBypassTxs must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"freeze_bypass_txs\""), value,
                       "freeze_bypass_txs must read back as ConfigSettingID.freezeBypassTxs")
    }

    func test_ConfigSettingID_CONFIG_SETTING_FREEZE_BYPASS_TXS_DELTA() throws {
        let value: ConfigSettingID = .freezeBypassTxsDelta
        XCTAssertEqual(try value.toXdrJson(), "\"freeze_bypass_txs_delta\"",
                       "ConfigSettingID.freezeBypassTxsDelta must render as freeze_bypass_txs_delta")
        XCTAssertEqual(value.rawValue, Int32(20),
                       "ConfigSettingID.freezeBypassTxsDelta must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"freeze_bypass_txs_delta\""), value,
                       "freeze_bypass_txs_delta must read back as ConfigSettingID.freezeBypassTxsDelta")
    }

    func test_ConfigSettingID_CONFIG_SETTING_FROZEN_LEDGER_KEYS() throws {
        let value: ConfigSettingID = .frozenLedgerKeys
        XCTAssertEqual(try value.toXdrJson(), "\"frozen_ledger_keys\"",
                       "ConfigSettingID.frozenLedgerKeys must render as frozen_ledger_keys")
        XCTAssertEqual(value.rawValue, Int32(17),
                       "ConfigSettingID.frozenLedgerKeys must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"frozen_ledger_keys\""), value,
                       "frozen_ledger_keys must read back as ConfigSettingID.frozenLedgerKeys")
    }

    func test_ConfigSettingID_CONFIG_SETTING_FROZEN_LEDGER_KEYS_DELTA() throws {
        let value: ConfigSettingID = .frozenLedgerKeysDelta
        XCTAssertEqual(try value.toXdrJson(), "\"frozen_ledger_keys_delta\"",
                       "ConfigSettingID.frozenLedgerKeysDelta must render as frozen_ledger_keys_delta")
        XCTAssertEqual(value.rawValue, Int32(18),
                       "ConfigSettingID.frozenLedgerKeysDelta must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"frozen_ledger_keys_delta\""), value,
                       "frozen_ledger_keys_delta must read back as ConfigSettingID.frozenLedgerKeysDelta")
    }

    func test_ConfigSettingID_CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW() throws {
        let value: ConfigSettingID = .liveSorobanStateSizeWindow
        XCTAssertEqual(try value.toXdrJson(), "\"live_soroban_state_size_window\"",
                       "ConfigSettingID.liveSorobanStateSizeWindow must render as live_soroban_state_size_window")
        XCTAssertEqual(value.rawValue, Int32(12),
                       "ConfigSettingID.liveSorobanStateSizeWindow must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"live_soroban_state_size_window\""), value,
                       "live_soroban_state_size_window must read back as ConfigSettingID.liveSorobanStateSizeWindow")
    }

    func test_ConfigSettingID_CONFIG_SETTING_SCP_TIMING() throws {
        let value: ConfigSettingID = .scpTiming
        XCTAssertEqual(try value.toXdrJson(), "\"scp_timing\"",
                       "ConfigSettingID.scpTiming must render as scp_timing")
        XCTAssertEqual(value.rawValue, Int32(16),
                       "ConfigSettingID.scpTiming must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"scp_timing\""), value,
                       "scp_timing must read back as ConfigSettingID.scpTiming")
    }

    func test_ConfigSettingID_CONFIG_SETTING_STATE_ARCHIVAL() throws {
        let value: ConfigSettingID = .stateArchival
        XCTAssertEqual(try value.toXdrJson(), "\"state_archival\"",
                       "ConfigSettingID.stateArchival must render as state_archival")
        XCTAssertEqual(value.rawValue, Int32(10),
                       "ConfigSettingID.stateArchival must keep its XDR value")
        XCTAssertEqual(try ConfigSettingID.fromXdrJson("\"state_archival\""), value,
                       "state_archival must read back as ConfigSettingID.stateArchival")
    }

    func test_ConfigSettingID_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ConfigSettingID.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ConfigSettingID: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ConfigSettingID")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ConfigSettingSCPTiming_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ConfigSettingSCPTiming.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ConfigSettingSCPTiming must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ConfigSettingSCPTiming_roundTrip() throws {
        let original: ConfigSettingSCPTiming = ConfigSettingSCPTiming(ledgerTargetCloseTimeMilliseconds: UInt32(42), nominationTimeoutInitialMilliseconds: UInt32(42), nominationTimeoutIncrementMilliseconds: UInt32(42), ballotTimeoutInitialMilliseconds: UInt32(42), ballotTimeoutIncrementMilliseconds: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConfigSettingSCPTiming.fromXdrJson(json)
        let viaValue = try ConfigSettingSCPTiming.fromXdrJsonValue(tree)
        let viaTree = try ConfigSettingSCPTiming.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConfigSettingSCPTiming must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConfigSettingSCPTiming must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConfigSettingSCPTiming must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConfigSettingSCPTiming must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConfigSettingSCPTiming must reach the same bytes through JSON and XDR")
    }

    func test_ContractCostParamEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ContractCostParamEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ContractCostParamEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ContractCostParamEntryXDR_roundTrip() throws {
        let original: ContractCostParamEntryXDR = ContractCostParamEntryXDR(ext: .void, constTerm: Int64(1234567), linearTerm: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractCostParamEntryXDR.fromXdrJson(json)
        let viaValue = try ContractCostParamEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ContractCostParamEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractCostParamEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractCostParamEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractCostParamEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractCostParamEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractCostParamEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractCostParamsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ContractCostParamsXDR.fromXdrJson("\"not_an_array\"")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ContractCostParamsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ContractCostParamsXDR_roundTrip() throws {
        let original: ContractCostParamsXDR = ContractCostParamsXDR(entries: [ContractCostParamEntryXDR(ext: .void, constTerm: Int64(1234567), linearTerm: Int64(1234567))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractCostParamsXDR.fromXdrJson(json)
        let viaValue = try ContractCostParamsXDR.fromXdrJsonValue(tree)
        let viaTree = try ContractCostParamsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractCostParamsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractCostParamsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractCostParamsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractCostParamsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractCostParamsXDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractCostType_Bls12381DecodeFp() throws {
        let value: ContractCostType = .bls12381DecodeFp
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_decode_fp\"",
                       "ContractCostType.bls12381DecodeFp must render as bls12381_decode_fp")
        XCTAssertEqual(value.rawValue, Int32(46),
                       "ContractCostType.bls12381DecodeFp must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_decode_fp\""), value,
                       "bls12381_decode_fp must read back as ContractCostType.bls12381DecodeFp")
    }

    func test_ContractCostType_Bls12381EncodeFp() throws {
        let value: ContractCostType = .bls12381EncodeFp
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_encode_fp\"",
                       "ContractCostType.bls12381EncodeFp must render as bls12381_encode_fp")
        XCTAssertEqual(value.rawValue, Int32(45),
                       "ContractCostType.bls12381EncodeFp must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_encode_fp\""), value,
                       "bls12381_encode_fp must read back as ContractCostType.bls12381EncodeFp")
    }

    func test_ContractCostType_Bls12381FrAddSub() throws {
        let value: ContractCostType = .bls12381FrAddSub
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_fr_add_sub\"",
                       "ContractCostType.bls12381FrAddSub must render as bls12381_fr_add_sub")
        XCTAssertEqual(value.rawValue, Int32(66),
                       "ContractCostType.bls12381FrAddSub must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_fr_add_sub\""), value,
                       "bls12381_fr_add_sub must read back as ContractCostType.bls12381FrAddSub")
    }

    func test_ContractCostType_Bls12381FrFromU256() throws {
        let value: ContractCostType = .bls12381FrFromU256
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_fr_from_u256\"",
                       "ContractCostType.bls12381FrFromU256 must render as bls12381_fr_from_u256")
        XCTAssertEqual(value.rawValue, Int32(64),
                       "ContractCostType.bls12381FrFromU256 must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_fr_from_u256\""), value,
                       "bls12381_fr_from_u256 must read back as ContractCostType.bls12381FrFromU256")
    }

    func test_ContractCostType_Bls12381FrInv() throws {
        let value: ContractCostType = .bls12381FrInv
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_fr_inv\"",
                       "ContractCostType.bls12381FrInv must render as bls12381_fr_inv")
        XCTAssertEqual(value.rawValue, Int32(69),
                       "ContractCostType.bls12381FrInv must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_fr_inv\""), value,
                       "bls12381_fr_inv must read back as ContractCostType.bls12381FrInv")
    }

    func test_ContractCostType_Bls12381FrMul() throws {
        let value: ContractCostType = .bls12381FrMul
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_fr_mul\"",
                       "ContractCostType.bls12381FrMul must render as bls12381_fr_mul")
        XCTAssertEqual(value.rawValue, Int32(67),
                       "ContractCostType.bls12381FrMul must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_fr_mul\""), value,
                       "bls12381_fr_mul must read back as ContractCostType.bls12381FrMul")
    }

    func test_ContractCostType_Bls12381FrPow() throws {
        let value: ContractCostType = .bls12381FrPow
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_fr_pow\"",
                       "ContractCostType.bls12381FrPow must render as bls12381_fr_pow")
        XCTAssertEqual(value.rawValue, Int32(68),
                       "ContractCostType.bls12381FrPow must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_fr_pow\""), value,
                       "bls12381_fr_pow must read back as ContractCostType.bls12381FrPow")
    }

    func test_ContractCostType_Bls12381FrToU256() throws {
        let value: ContractCostType = .bls12381FrToU256
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_fr_to_u256\"",
                       "ContractCostType.bls12381FrToU256 must render as bls12381_fr_to_u256")
        XCTAssertEqual(value.rawValue, Int32(65),
                       "ContractCostType.bls12381FrToU256 must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_fr_to_u256\""), value,
                       "bls12381_fr_to_u256 must read back as ContractCostType.bls12381FrToU256")
    }

    func test_ContractCostType_Bls12381G1Add() throws {
        let value: ContractCostType = .bls12381G1Add
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_g1_add\"",
                       "ContractCostType.bls12381G1Add must render as bls12381_g1_add")
        XCTAssertEqual(value.rawValue, Int32(53),
                       "ContractCostType.bls12381G1Add must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_g1_add\""), value,
                       "bls12381_g1_add must read back as ContractCostType.bls12381G1Add")
    }

    func test_ContractCostType_Bls12381G1CheckPointInSubgroup() throws {
        let value: ContractCostType = .bls12381G1CheckPointInSubgroup
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_g1_check_point_in_subgroup\"",
                       "ContractCostType.bls12381G1CheckPointInSubgroup must render as bls12381_g1_check_point_in_subgroup")
        XCTAssertEqual(value.rawValue, Int32(48),
                       "ContractCostType.bls12381G1CheckPointInSubgroup must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_g1_check_point_in_subgroup\""), value,
                       "bls12381_g1_check_point_in_subgroup must read back as ContractCostType.bls12381G1CheckPointInSubgroup")
    }

    func test_ContractCostType_Bls12381G1CheckPointOnCurve() throws {
        let value: ContractCostType = .bls12381G1CheckPointOnCurve
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_g1_check_point_on_curve\"",
                       "ContractCostType.bls12381G1CheckPointOnCurve must render as bls12381_g1_check_point_on_curve")
        XCTAssertEqual(value.rawValue, Int32(47),
                       "ContractCostType.bls12381G1CheckPointOnCurve must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_g1_check_point_on_curve\""), value,
                       "bls12381_g1_check_point_on_curve must read back as ContractCostType.bls12381G1CheckPointOnCurve")
    }

    func test_ContractCostType_Bls12381G1Msm() throws {
        let value: ContractCostType = .bls12381G1Msm
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_g1_msm\"",
                       "ContractCostType.bls12381G1Msm must render as bls12381_g1_msm")
        XCTAssertEqual(value.rawValue, Int32(55),
                       "ContractCostType.bls12381G1Msm must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_g1_msm\""), value,
                       "bls12381_g1_msm must read back as ContractCostType.bls12381G1Msm")
    }

    func test_ContractCostType_Bls12381G1Mul() throws {
        let value: ContractCostType = .bls12381G1Mul
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_g1_mul\"",
                       "ContractCostType.bls12381G1Mul must render as bls12381_g1_mul")
        XCTAssertEqual(value.rawValue, Int32(54),
                       "ContractCostType.bls12381G1Mul must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_g1_mul\""), value,
                       "bls12381_g1_mul must read back as ContractCostType.bls12381G1Mul")
    }

    func test_ContractCostType_Bls12381G1ProjectiveToAffine() throws {
        let value: ContractCostType = .bls12381G1ProjectiveToAffine
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_g1_projective_to_affine\"",
                       "ContractCostType.bls12381G1ProjectiveToAffine must render as bls12381_g1_projective_to_affine")
        XCTAssertEqual(value.rawValue, Int32(51),
                       "ContractCostType.bls12381G1ProjectiveToAffine must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_g1_projective_to_affine\""), value,
                       "bls12381_g1_projective_to_affine must read back as ContractCostType.bls12381G1ProjectiveToAffine")
    }

    func test_ContractCostType_Bls12381G2Add() throws {
        let value: ContractCostType = .bls12381G2Add
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_g2_add\"",
                       "ContractCostType.bls12381G2Add must render as bls12381_g2_add")
        XCTAssertEqual(value.rawValue, Int32(58),
                       "ContractCostType.bls12381G2Add must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_g2_add\""), value,
                       "bls12381_g2_add must read back as ContractCostType.bls12381G2Add")
    }

    func test_ContractCostType_Bls12381G2CheckPointInSubgroup() throws {
        let value: ContractCostType = .bls12381G2CheckPointInSubgroup
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_g2_check_point_in_subgroup\"",
                       "ContractCostType.bls12381G2CheckPointInSubgroup must render as bls12381_g2_check_point_in_subgroup")
        XCTAssertEqual(value.rawValue, Int32(50),
                       "ContractCostType.bls12381G2CheckPointInSubgroup must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_g2_check_point_in_subgroup\""), value,
                       "bls12381_g2_check_point_in_subgroup must read back as ContractCostType.bls12381G2CheckPointInSubgroup")
    }

    func test_ContractCostType_Bls12381G2CheckPointOnCurve() throws {
        let value: ContractCostType = .bls12381G2CheckPointOnCurve
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_g2_check_point_on_curve\"",
                       "ContractCostType.bls12381G2CheckPointOnCurve must render as bls12381_g2_check_point_on_curve")
        XCTAssertEqual(value.rawValue, Int32(49),
                       "ContractCostType.bls12381G2CheckPointOnCurve must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_g2_check_point_on_curve\""), value,
                       "bls12381_g2_check_point_on_curve must read back as ContractCostType.bls12381G2CheckPointOnCurve")
    }

    func test_ContractCostType_Bls12381G2Msm() throws {
        let value: ContractCostType = .bls12381G2Msm
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_g2_msm\"",
                       "ContractCostType.bls12381G2Msm must render as bls12381_g2_msm")
        XCTAssertEqual(value.rawValue, Int32(60),
                       "ContractCostType.bls12381G2Msm must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_g2_msm\""), value,
                       "bls12381_g2_msm must read back as ContractCostType.bls12381G2Msm")
    }

    func test_ContractCostType_Bls12381G2Mul() throws {
        let value: ContractCostType = .bls12381G2Mul
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_g2_mul\"",
                       "ContractCostType.bls12381G2Mul must render as bls12381_g2_mul")
        XCTAssertEqual(value.rawValue, Int32(59),
                       "ContractCostType.bls12381G2Mul must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_g2_mul\""), value,
                       "bls12381_g2_mul must read back as ContractCostType.bls12381G2Mul")
    }

    func test_ContractCostType_Bls12381G2ProjectiveToAffine() throws {
        let value: ContractCostType = .bls12381G2ProjectiveToAffine
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_g2_projective_to_affine\"",
                       "ContractCostType.bls12381G2ProjectiveToAffine must render as bls12381_g2_projective_to_affine")
        XCTAssertEqual(value.rawValue, Int32(52),
                       "ContractCostType.bls12381G2ProjectiveToAffine must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_g2_projective_to_affine\""), value,
                       "bls12381_g2_projective_to_affine must read back as ContractCostType.bls12381G2ProjectiveToAffine")
    }

    func test_ContractCostType_Bls12381HashToG1() throws {
        let value: ContractCostType = .bls12381HashToG1
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_hash_to_g1\"",
                       "ContractCostType.bls12381HashToG1 must render as bls12381_hash_to_g1")
        XCTAssertEqual(value.rawValue, Int32(57),
                       "ContractCostType.bls12381HashToG1 must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_hash_to_g1\""), value,
                       "bls12381_hash_to_g1 must read back as ContractCostType.bls12381HashToG1")
    }

    func test_ContractCostType_Bls12381HashToG2() throws {
        let value: ContractCostType = .bls12381HashToG2
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_hash_to_g2\"",
                       "ContractCostType.bls12381HashToG2 must render as bls12381_hash_to_g2")
        XCTAssertEqual(value.rawValue, Int32(62),
                       "ContractCostType.bls12381HashToG2 must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_hash_to_g2\""), value,
                       "bls12381_hash_to_g2 must read back as ContractCostType.bls12381HashToG2")
    }

    func test_ContractCostType_Bls12381MapFp2ToG2() throws {
        let value: ContractCostType = .bls12381MapFp2ToG2
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_map_fp2_to_g2\"",
                       "ContractCostType.bls12381MapFp2ToG2 must render as bls12381_map_fp2_to_g2")
        XCTAssertEqual(value.rawValue, Int32(61),
                       "ContractCostType.bls12381MapFp2ToG2 must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_map_fp2_to_g2\""), value,
                       "bls12381_map_fp2_to_g2 must read back as ContractCostType.bls12381MapFp2ToG2")
    }

    func test_ContractCostType_Bls12381MapFpToG1() throws {
        let value: ContractCostType = .bls12381MapFpToG1
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_map_fp_to_g1\"",
                       "ContractCostType.bls12381MapFpToG1 must render as bls12381_map_fp_to_g1")
        XCTAssertEqual(value.rawValue, Int32(56),
                       "ContractCostType.bls12381MapFpToG1 must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_map_fp_to_g1\""), value,
                       "bls12381_map_fp_to_g1 must read back as ContractCostType.bls12381MapFpToG1")
    }

    func test_ContractCostType_Bls12381Pairing() throws {
        let value: ContractCostType = .bls12381Pairing
        XCTAssertEqual(try value.toXdrJson(), "\"bls12381_pairing\"",
                       "ContractCostType.bls12381Pairing must render as bls12381_pairing")
        XCTAssertEqual(value.rawValue, Int32(63),
                       "ContractCostType.bls12381Pairing must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bls12381_pairing\""), value,
                       "bls12381_pairing must read back as ContractCostType.bls12381Pairing")
    }

    func test_ContractCostType_Bn254DecodeFp() throws {
        let value: ContractCostType = .bn254DecodeFp
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_decode_fp\"",
                       "ContractCostType.bn254DecodeFp must render as bn254_decode_fp")
        XCTAssertEqual(value.rawValue, Int32(71),
                       "ContractCostType.bn254DecodeFp must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_decode_fp\""), value,
                       "bn254_decode_fp must read back as ContractCostType.bn254DecodeFp")
    }

    func test_ContractCostType_Bn254EncodeFp() throws {
        let value: ContractCostType = .bn254EncodeFp
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_encode_fp\"",
                       "ContractCostType.bn254EncodeFp must render as bn254_encode_fp")
        XCTAssertEqual(value.rawValue, Int32(70),
                       "ContractCostType.bn254EncodeFp must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_encode_fp\""), value,
                       "bn254_encode_fp must read back as ContractCostType.bn254EncodeFp")
    }

    func test_ContractCostType_Bn254FrAddSub() throws {
        let value: ContractCostType = .bn254FrAddSub
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_fr_add_sub\"",
                       "ContractCostType.bn254FrAddSub must render as bn254_fr_add_sub")
        XCTAssertEqual(value.rawValue, Int32(81),
                       "ContractCostType.bn254FrAddSub must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_fr_add_sub\""), value,
                       "bn254_fr_add_sub must read back as ContractCostType.bn254FrAddSub")
    }

    func test_ContractCostType_Bn254FrFromU256() throws {
        let value: ContractCostType = .bn254FrFromU256
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_fr_from_u256\"",
                       "ContractCostType.bn254FrFromU256 must render as bn254_fr_from_u256")
        XCTAssertEqual(value.rawValue, Int32(79),
                       "ContractCostType.bn254FrFromU256 must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_fr_from_u256\""), value,
                       "bn254_fr_from_u256 must read back as ContractCostType.bn254FrFromU256")
    }

    func test_ContractCostType_Bn254FrInv() throws {
        let value: ContractCostType = .bn254FrInv
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_fr_inv\"",
                       "ContractCostType.bn254FrInv must render as bn254_fr_inv")
        XCTAssertEqual(value.rawValue, Int32(84),
                       "ContractCostType.bn254FrInv must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_fr_inv\""), value,
                       "bn254_fr_inv must read back as ContractCostType.bn254FrInv")
    }

    func test_ContractCostType_Bn254FrMul() throws {
        let value: ContractCostType = .bn254FrMul
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_fr_mul\"",
                       "ContractCostType.bn254FrMul must render as bn254_fr_mul")
        XCTAssertEqual(value.rawValue, Int32(82),
                       "ContractCostType.bn254FrMul must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_fr_mul\""), value,
                       "bn254_fr_mul must read back as ContractCostType.bn254FrMul")
    }

    func test_ContractCostType_Bn254FrPow() throws {
        let value: ContractCostType = .bn254FrPow
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_fr_pow\"",
                       "ContractCostType.bn254FrPow must render as bn254_fr_pow")
        XCTAssertEqual(value.rawValue, Int32(83),
                       "ContractCostType.bn254FrPow must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_fr_pow\""), value,
                       "bn254_fr_pow must read back as ContractCostType.bn254FrPow")
    }

    func test_ContractCostType_Bn254FrToU256() throws {
        let value: ContractCostType = .bn254FrToU256
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_fr_to_u256\"",
                       "ContractCostType.bn254FrToU256 must render as bn254_fr_to_u256")
        XCTAssertEqual(value.rawValue, Int32(80),
                       "ContractCostType.bn254FrToU256 must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_fr_to_u256\""), value,
                       "bn254_fr_to_u256 must read back as ContractCostType.bn254FrToU256")
    }

    func test_ContractCostType_Bn254G1Add() throws {
        let value: ContractCostType = .bn254G1Add
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_g1_add\"",
                       "ContractCostType.bn254G1Add must render as bn254_g1_add")
        XCTAssertEqual(value.rawValue, Int32(76),
                       "ContractCostType.bn254G1Add must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_g1_add\""), value,
                       "bn254_g1_add must read back as ContractCostType.bn254G1Add")
    }

    func test_ContractCostType_Bn254G1CheckPointOnCurve() throws {
        let value: ContractCostType = .bn254G1CheckPointOnCurve
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_g1_check_point_on_curve\"",
                       "ContractCostType.bn254G1CheckPointOnCurve must render as bn254_g1_check_point_on_curve")
        XCTAssertEqual(value.rawValue, Int32(72),
                       "ContractCostType.bn254G1CheckPointOnCurve must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_g1_check_point_on_curve\""), value,
                       "bn254_g1_check_point_on_curve must read back as ContractCostType.bn254G1CheckPointOnCurve")
    }

    func test_ContractCostType_Bn254G1Msm() throws {
        let value: ContractCostType = .bn254G1Msm
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_g1_msm\"",
                       "ContractCostType.bn254G1Msm must render as bn254_g1_msm")
        XCTAssertEqual(value.rawValue, Int32(85),
                       "ContractCostType.bn254G1Msm must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_g1_msm\""), value,
                       "bn254_g1_msm must read back as ContractCostType.bn254G1Msm")
    }

    func test_ContractCostType_Bn254G1Mul() throws {
        let value: ContractCostType = .bn254G1Mul
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_g1_mul\"",
                       "ContractCostType.bn254G1Mul must render as bn254_g1_mul")
        XCTAssertEqual(value.rawValue, Int32(77),
                       "ContractCostType.bn254G1Mul must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_g1_mul\""), value,
                       "bn254_g1_mul must read back as ContractCostType.bn254G1Mul")
    }

    func test_ContractCostType_Bn254G1ProjectiveToAffine() throws {
        let value: ContractCostType = .bn254G1ProjectiveToAffine
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_g1_projective_to_affine\"",
                       "ContractCostType.bn254G1ProjectiveToAffine must render as bn254_g1_projective_to_affine")
        XCTAssertEqual(value.rawValue, Int32(75),
                       "ContractCostType.bn254G1ProjectiveToAffine must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_g1_projective_to_affine\""), value,
                       "bn254_g1_projective_to_affine must read back as ContractCostType.bn254G1ProjectiveToAffine")
    }

    func test_ContractCostType_Bn254G2CheckPointInSubgroup() throws {
        let value: ContractCostType = .bn254G2CheckPointInSubgroup
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_g2_check_point_in_subgroup\"",
                       "ContractCostType.bn254G2CheckPointInSubgroup must render as bn254_g2_check_point_in_subgroup")
        XCTAssertEqual(value.rawValue, Int32(74),
                       "ContractCostType.bn254G2CheckPointInSubgroup must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_g2_check_point_in_subgroup\""), value,
                       "bn254_g2_check_point_in_subgroup must read back as ContractCostType.bn254G2CheckPointInSubgroup")
    }

    func test_ContractCostType_Bn254G2CheckPointOnCurve() throws {
        let value: ContractCostType = .bn254G2CheckPointOnCurve
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_g2_check_point_on_curve\"",
                       "ContractCostType.bn254G2CheckPointOnCurve must render as bn254_g2_check_point_on_curve")
        XCTAssertEqual(value.rawValue, Int32(73),
                       "ContractCostType.bn254G2CheckPointOnCurve must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_g2_check_point_on_curve\""), value,
                       "bn254_g2_check_point_on_curve must read back as ContractCostType.bn254G2CheckPointOnCurve")
    }

    func test_ContractCostType_Bn254Pairing() throws {
        let value: ContractCostType = .bn254Pairing
        XCTAssertEqual(try value.toXdrJson(), "\"bn254_pairing\"",
                       "ContractCostType.bn254Pairing must render as bn254_pairing")
        XCTAssertEqual(value.rawValue, Int32(78),
                       "ContractCostType.bn254Pairing must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"bn254_pairing\""), value,
                       "bn254_pairing must read back as ContractCostType.bn254Pairing")
    }

    func test_ContractCostType_ChaCha20DrawBytes() throws {
        let value: ContractCostType = .chaCha20DrawBytes
        XCTAssertEqual(try value.toXdrJson(), "\"cha_cha20_draw_bytes\"",
                       "ContractCostType.chaCha20DrawBytes must render as cha_cha20_draw_bytes")
        XCTAssertEqual(value.rawValue, Int32(22),
                       "ContractCostType.chaCha20DrawBytes must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"cha_cha20_draw_bytes\""), value,
                       "cha_cha20_draw_bytes must read back as ContractCostType.chaCha20DrawBytes")
    }

    func test_ContractCostType_ComputeEd25519PubKey() throws {
        let value: ContractCostType = .computeEd25519PubKey
        XCTAssertEqual(try value.toXdrJson(), "\"compute_ed25519_pub_key\"",
                       "ContractCostType.computeEd25519PubKey must render as compute_ed25519_pub_key")
        XCTAssertEqual(value.rawValue, Int32(9),
                       "ContractCostType.computeEd25519PubKey must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"compute_ed25519_pub_key\""), value,
                       "compute_ed25519_pub_key must read back as ContractCostType.computeEd25519PubKey")
    }

    func test_ContractCostType_ComputeKeccak256Hash() throws {
        let value: ContractCostType = .computeKeccak256Hash
        XCTAssertEqual(try value.toXdrJson(), "\"compute_keccak256_hash\"",
                       "ContractCostType.computeKeccak256Hash must render as compute_keccak256_hash")
        XCTAssertEqual(value.rawValue, Int32(14),
                       "ContractCostType.computeKeccak256Hash must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"compute_keccak256_hash\""), value,
                       "compute_keccak256_hash must read back as ContractCostType.computeKeccak256Hash")
    }

    func test_ContractCostType_ComputeSha256Hash() throws {
        let value: ContractCostType = .computeSha256Hash
        XCTAssertEqual(try value.toXdrJson(), "\"compute_sha256_hash\"",
                       "ContractCostType.computeSha256Hash must render as compute_sha256_hash")
        XCTAssertEqual(value.rawValue, Int32(8),
                       "ContractCostType.computeSha256Hash must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"compute_sha256_hash\""), value,
                       "compute_sha256_hash must read back as ContractCostType.computeSha256Hash")
    }

    func test_ContractCostType_DecodeEcdsaCurve256Sig() throws {
        let value: ContractCostType = .decodeEcdsaCurve256Sig
        XCTAssertEqual(try value.toXdrJson(), "\"decode_ecdsa_curve256_sig\"",
                       "ContractCostType.decodeEcdsaCurve256Sig must render as decode_ecdsa_curve256_sig")
        XCTAssertEqual(value.rawValue, Int32(15),
                       "ContractCostType.decodeEcdsaCurve256Sig must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"decode_ecdsa_curve256_sig\""), value,
                       "decode_ecdsa_curve256_sig must read back as ContractCostType.decodeEcdsaCurve256Sig")
    }

    func test_ContractCostType_DispatchHostFunction() throws {
        let value: ContractCostType = .dispatchHostFunction
        XCTAssertEqual(try value.toXdrJson(), "\"dispatch_host_function\"",
                       "ContractCostType.dispatchHostFunction must render as dispatch_host_function")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "ContractCostType.dispatchHostFunction must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"dispatch_host_function\""), value,
                       "dispatch_host_function must read back as ContractCostType.dispatchHostFunction")
    }

    func test_ContractCostType_InstantiateWasmDataSegmentBytes() throws {
        let value: ContractCostType = .instantiateWasmDataSegmentBytes
        XCTAssertEqual(try value.toXdrJson(), "\"instantiate_wasm_data_segment_bytes\"",
                       "ContractCostType.instantiateWasmDataSegmentBytes must render as instantiate_wasm_data_segment_bytes")
        XCTAssertEqual(value.rawValue, Int32(42),
                       "ContractCostType.instantiateWasmDataSegmentBytes must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"instantiate_wasm_data_segment_bytes\""), value,
                       "instantiate_wasm_data_segment_bytes must read back as ContractCostType.instantiateWasmDataSegmentBytes")
    }

    func test_ContractCostType_InstantiateWasmDataSegments() throws {
        let value: ContractCostType = .instantiateWasmDataSegments
        XCTAssertEqual(try value.toXdrJson(), "\"instantiate_wasm_data_segments\"",
                       "ContractCostType.instantiateWasmDataSegments must render as instantiate_wasm_data_segments")
        XCTAssertEqual(value.rawValue, Int32(38),
                       "ContractCostType.instantiateWasmDataSegments must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"instantiate_wasm_data_segments\""), value,
                       "instantiate_wasm_data_segments must read back as ContractCostType.instantiateWasmDataSegments")
    }

    func test_ContractCostType_InstantiateWasmElemSegments() throws {
        let value: ContractCostType = .instantiateWasmElemSegments
        XCTAssertEqual(try value.toXdrJson(), "\"instantiate_wasm_elem_segments\"",
                       "ContractCostType.instantiateWasmElemSegments must render as instantiate_wasm_elem_segments")
        XCTAssertEqual(value.rawValue, Int32(39),
                       "ContractCostType.instantiateWasmElemSegments must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"instantiate_wasm_elem_segments\""), value,
                       "instantiate_wasm_elem_segments must read back as ContractCostType.instantiateWasmElemSegments")
    }

    func test_ContractCostType_InstantiateWasmExports() throws {
        let value: ContractCostType = .instantiateWasmExports
        XCTAssertEqual(try value.toXdrJson(), "\"instantiate_wasm_exports\"",
                       "ContractCostType.instantiateWasmExports must render as instantiate_wasm_exports")
        XCTAssertEqual(value.rawValue, Int32(41),
                       "ContractCostType.instantiateWasmExports must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"instantiate_wasm_exports\""), value,
                       "instantiate_wasm_exports must read back as ContractCostType.instantiateWasmExports")
    }

    func test_ContractCostType_InstantiateWasmFunctions() throws {
        let value: ContractCostType = .instantiateWasmFunctions
        XCTAssertEqual(try value.toXdrJson(), "\"instantiate_wasm_functions\"",
                       "ContractCostType.instantiateWasmFunctions must render as instantiate_wasm_functions")
        XCTAssertEqual(value.rawValue, Int32(34),
                       "ContractCostType.instantiateWasmFunctions must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"instantiate_wasm_functions\""), value,
                       "instantiate_wasm_functions must read back as ContractCostType.instantiateWasmFunctions")
    }

    func test_ContractCostType_InstantiateWasmGlobals() throws {
        let value: ContractCostType = .instantiateWasmGlobals
        XCTAssertEqual(try value.toXdrJson(), "\"instantiate_wasm_globals\"",
                       "ContractCostType.instantiateWasmGlobals must render as instantiate_wasm_globals")
        XCTAssertEqual(value.rawValue, Int32(35),
                       "ContractCostType.instantiateWasmGlobals must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"instantiate_wasm_globals\""), value,
                       "instantiate_wasm_globals must read back as ContractCostType.instantiateWasmGlobals")
    }

    func test_ContractCostType_InstantiateWasmImports() throws {
        let value: ContractCostType = .instantiateWasmImports
        XCTAssertEqual(try value.toXdrJson(), "\"instantiate_wasm_imports\"",
                       "ContractCostType.instantiateWasmImports must render as instantiate_wasm_imports")
        XCTAssertEqual(value.rawValue, Int32(40),
                       "ContractCostType.instantiateWasmImports must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"instantiate_wasm_imports\""), value,
                       "instantiate_wasm_imports must read back as ContractCostType.instantiateWasmImports")
    }

    func test_ContractCostType_InstantiateWasmInstructions() throws {
        let value: ContractCostType = .instantiateWasmInstructions
        XCTAssertEqual(try value.toXdrJson(), "\"instantiate_wasm_instructions\"",
                       "ContractCostType.instantiateWasmInstructions must render as instantiate_wasm_instructions")
        XCTAssertEqual(value.rawValue, Int32(33),
                       "ContractCostType.instantiateWasmInstructions must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"instantiate_wasm_instructions\""), value,
                       "instantiate_wasm_instructions must read back as ContractCostType.instantiateWasmInstructions")
    }

    func test_ContractCostType_InstantiateWasmTableEntries() throws {
        let value: ContractCostType = .instantiateWasmTableEntries
        XCTAssertEqual(try value.toXdrJson(), "\"instantiate_wasm_table_entries\"",
                       "ContractCostType.instantiateWasmTableEntries must render as instantiate_wasm_table_entries")
        XCTAssertEqual(value.rawValue, Int32(36),
                       "ContractCostType.instantiateWasmTableEntries must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"instantiate_wasm_table_entries\""), value,
                       "instantiate_wasm_table_entries must read back as ContractCostType.instantiateWasmTableEntries")
    }

    func test_ContractCostType_InstantiateWasmTypes() throws {
        let value: ContractCostType = .instantiateWasmTypes
        XCTAssertEqual(try value.toXdrJson(), "\"instantiate_wasm_types\"",
                       "ContractCostType.instantiateWasmTypes must render as instantiate_wasm_types")
        XCTAssertEqual(value.rawValue, Int32(37),
                       "ContractCostType.instantiateWasmTypes must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"instantiate_wasm_types\""), value,
                       "instantiate_wasm_types must read back as ContractCostType.instantiateWasmTypes")
    }

    func test_ContractCostType_Int256AddSub() throws {
        let value: ContractCostType = .int256AddSub
        XCTAssertEqual(try value.toXdrJson(), "\"int256_add_sub\"",
                       "ContractCostType.int256AddSub must render as int256_add_sub")
        XCTAssertEqual(value.rawValue, Int32(17),
                       "ContractCostType.int256AddSub must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"int256_add_sub\""), value,
                       "int256_add_sub must read back as ContractCostType.int256AddSub")
    }

    func test_ContractCostType_Int256Div() throws {
        let value: ContractCostType = .int256Div
        XCTAssertEqual(try value.toXdrJson(), "\"int256_div\"",
                       "ContractCostType.int256Div must render as int256_div")
        XCTAssertEqual(value.rawValue, Int32(19),
                       "ContractCostType.int256Div must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"int256_div\""), value,
                       "int256_div must read back as ContractCostType.int256Div")
    }

    func test_ContractCostType_Int256Mul() throws {
        let value: ContractCostType = .int256Mul
        XCTAssertEqual(try value.toXdrJson(), "\"int256_mul\"",
                       "ContractCostType.int256Mul must render as int256_mul")
        XCTAssertEqual(value.rawValue, Int32(18),
                       "ContractCostType.int256Mul must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"int256_mul\""), value,
                       "int256_mul must read back as ContractCostType.int256Mul")
    }

    func test_ContractCostType_Int256Pow() throws {
        let value: ContractCostType = .int256Pow
        XCTAssertEqual(try value.toXdrJson(), "\"int256_pow\"",
                       "ContractCostType.int256Pow must render as int256_pow")
        XCTAssertEqual(value.rawValue, Int32(20),
                       "ContractCostType.int256Pow must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"int256_pow\""), value,
                       "int256_pow must read back as ContractCostType.int256Pow")
    }

    func test_ContractCostType_Int256Shift() throws {
        let value: ContractCostType = .int256Shift
        XCTAssertEqual(try value.toXdrJson(), "\"int256_shift\"",
                       "ContractCostType.int256Shift must render as int256_shift")
        XCTAssertEqual(value.rawValue, Int32(21),
                       "ContractCostType.int256Shift must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"int256_shift\""), value,
                       "int256_shift must read back as ContractCostType.int256Shift")
    }

    func test_ContractCostType_InvokeVmFunction() throws {
        let value: ContractCostType = .invokeVmFunction
        XCTAssertEqual(try value.toXdrJson(), "\"invoke_vm_function\"",
                       "ContractCostType.invokeVmFunction must render as invoke_vm_function")
        XCTAssertEqual(value.rawValue, Int32(13),
                       "ContractCostType.invokeVmFunction must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"invoke_vm_function\""), value,
                       "invoke_vm_function must read back as ContractCostType.invokeVmFunction")
    }

    func test_ContractCostType_MemAlloc() throws {
        let value: ContractCostType = .memAlloc
        XCTAssertEqual(try value.toXdrJson(), "\"mem_alloc\"",
                       "ContractCostType.memAlloc must render as mem_alloc")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "ContractCostType.memAlloc must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"mem_alloc\""), value,
                       "mem_alloc must read back as ContractCostType.memAlloc")
    }

    func test_ContractCostType_MemCmp() throws {
        let value: ContractCostType = .memCmp
        XCTAssertEqual(try value.toXdrJson(), "\"mem_cmp\"",
                       "ContractCostType.memCmp must render as mem_cmp")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "ContractCostType.memCmp must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"mem_cmp\""), value,
                       "mem_cmp must read back as ContractCostType.memCmp")
    }

    func test_ContractCostType_MemCpy() throws {
        let value: ContractCostType = .memCpy
        XCTAssertEqual(try value.toXdrJson(), "\"mem_cpy\"",
                       "ContractCostType.memCpy must render as mem_cpy")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "ContractCostType.memCpy must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"mem_cpy\""), value,
                       "mem_cpy must read back as ContractCostType.memCpy")
    }

    func test_ContractCostType_ParseWasmDataSegmentBytes() throws {
        let value: ContractCostType = .parseWasmDataSegmentBytes
        XCTAssertEqual(try value.toXdrJson(), "\"parse_wasm_data_segment_bytes\"",
                       "ContractCostType.parseWasmDataSegmentBytes must render as parse_wasm_data_segment_bytes")
        XCTAssertEqual(value.rawValue, Int32(32),
                       "ContractCostType.parseWasmDataSegmentBytes must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"parse_wasm_data_segment_bytes\""), value,
                       "parse_wasm_data_segment_bytes must read back as ContractCostType.parseWasmDataSegmentBytes")
    }

    func test_ContractCostType_ParseWasmDataSegments() throws {
        let value: ContractCostType = .parseWasmDataSegments
        XCTAssertEqual(try value.toXdrJson(), "\"parse_wasm_data_segments\"",
                       "ContractCostType.parseWasmDataSegments must render as parse_wasm_data_segments")
        XCTAssertEqual(value.rawValue, Int32(28),
                       "ContractCostType.parseWasmDataSegments must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"parse_wasm_data_segments\""), value,
                       "parse_wasm_data_segments must read back as ContractCostType.parseWasmDataSegments")
    }

    func test_ContractCostType_ParseWasmElemSegments() throws {
        let value: ContractCostType = .parseWasmElemSegments
        XCTAssertEqual(try value.toXdrJson(), "\"parse_wasm_elem_segments\"",
                       "ContractCostType.parseWasmElemSegments must render as parse_wasm_elem_segments")
        XCTAssertEqual(value.rawValue, Int32(29),
                       "ContractCostType.parseWasmElemSegments must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"parse_wasm_elem_segments\""), value,
                       "parse_wasm_elem_segments must read back as ContractCostType.parseWasmElemSegments")
    }

    func test_ContractCostType_ParseWasmExports() throws {
        let value: ContractCostType = .parseWasmExports
        XCTAssertEqual(try value.toXdrJson(), "\"parse_wasm_exports\"",
                       "ContractCostType.parseWasmExports must render as parse_wasm_exports")
        XCTAssertEqual(value.rawValue, Int32(31),
                       "ContractCostType.parseWasmExports must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"parse_wasm_exports\""), value,
                       "parse_wasm_exports must read back as ContractCostType.parseWasmExports")
    }

    func test_ContractCostType_ParseWasmFunctions() throws {
        let value: ContractCostType = .parseWasmFunctions
        XCTAssertEqual(try value.toXdrJson(), "\"parse_wasm_functions\"",
                       "ContractCostType.parseWasmFunctions must render as parse_wasm_functions")
        XCTAssertEqual(value.rawValue, Int32(24),
                       "ContractCostType.parseWasmFunctions must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"parse_wasm_functions\""), value,
                       "parse_wasm_functions must read back as ContractCostType.parseWasmFunctions")
    }

    func test_ContractCostType_ParseWasmGlobals() throws {
        let value: ContractCostType = .parseWasmGlobals
        XCTAssertEqual(try value.toXdrJson(), "\"parse_wasm_globals\"",
                       "ContractCostType.parseWasmGlobals must render as parse_wasm_globals")
        XCTAssertEqual(value.rawValue, Int32(25),
                       "ContractCostType.parseWasmGlobals must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"parse_wasm_globals\""), value,
                       "parse_wasm_globals must read back as ContractCostType.parseWasmGlobals")
    }

    func test_ContractCostType_ParseWasmImports() throws {
        let value: ContractCostType = .parseWasmImports
        XCTAssertEqual(try value.toXdrJson(), "\"parse_wasm_imports\"",
                       "ContractCostType.parseWasmImports must render as parse_wasm_imports")
        XCTAssertEqual(value.rawValue, Int32(30),
                       "ContractCostType.parseWasmImports must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"parse_wasm_imports\""), value,
                       "parse_wasm_imports must read back as ContractCostType.parseWasmImports")
    }

    func test_ContractCostType_ParseWasmInstructions() throws {
        let value: ContractCostType = .parseWasmInstructions
        XCTAssertEqual(try value.toXdrJson(), "\"parse_wasm_instructions\"",
                       "ContractCostType.parseWasmInstructions must render as parse_wasm_instructions")
        XCTAssertEqual(value.rawValue, Int32(23),
                       "ContractCostType.parseWasmInstructions must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"parse_wasm_instructions\""), value,
                       "parse_wasm_instructions must read back as ContractCostType.parseWasmInstructions")
    }

    func test_ContractCostType_ParseWasmTableEntries() throws {
        let value: ContractCostType = .parseWasmTableEntries
        XCTAssertEqual(try value.toXdrJson(), "\"parse_wasm_table_entries\"",
                       "ContractCostType.parseWasmTableEntries must render as parse_wasm_table_entries")
        XCTAssertEqual(value.rawValue, Int32(26),
                       "ContractCostType.parseWasmTableEntries must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"parse_wasm_table_entries\""), value,
                       "parse_wasm_table_entries must read back as ContractCostType.parseWasmTableEntries")
    }

    func test_ContractCostType_ParseWasmTypes() throws {
        let value: ContractCostType = .parseWasmTypes
        XCTAssertEqual(try value.toXdrJson(), "\"parse_wasm_types\"",
                       "ContractCostType.parseWasmTypes must render as parse_wasm_types")
        XCTAssertEqual(value.rawValue, Int32(27),
                       "ContractCostType.parseWasmTypes must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"parse_wasm_types\""), value,
                       "parse_wasm_types must read back as ContractCostType.parseWasmTypes")
    }

    func test_ContractCostType_RecoverEcdsaSecp256k1Key() throws {
        let value: ContractCostType = .recoverEcdsaSecp256k1Key
        XCTAssertEqual(try value.toXdrJson(), "\"recover_ecdsa_secp256k1_key\"",
                       "ContractCostType.recoverEcdsaSecp256k1Key must render as recover_ecdsa_secp256k1_key")
        XCTAssertEqual(value.rawValue, Int32(16),
                       "ContractCostType.recoverEcdsaSecp256k1Key must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"recover_ecdsa_secp256k1_key\""), value,
                       "recover_ecdsa_secp256k1_key must read back as ContractCostType.recoverEcdsaSecp256k1Key")
    }

    func test_ContractCostType_Sec1DecodePointUncompressed() throws {
        let value: ContractCostType = .sec1DecodePointUncompressed
        XCTAssertEqual(try value.toXdrJson(), "\"sec1_decode_point_uncompressed\"",
                       "ContractCostType.sec1DecodePointUncompressed must render as sec1_decode_point_uncompressed")
        XCTAssertEqual(value.rawValue, Int32(43),
                       "ContractCostType.sec1DecodePointUncompressed must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"sec1_decode_point_uncompressed\""), value,
                       "sec1_decode_point_uncompressed must read back as ContractCostType.sec1DecodePointUncompressed")
    }

    func test_ContractCostType_ValDeser() throws {
        let value: ContractCostType = .valDeser
        XCTAssertEqual(try value.toXdrJson(), "\"val_deser\"",
                       "ContractCostType.valDeser must render as val_deser")
        XCTAssertEqual(value.rawValue, Int32(7),
                       "ContractCostType.valDeser must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"val_deser\""), value,
                       "val_deser must read back as ContractCostType.valDeser")
    }

    func test_ContractCostType_ValSer() throws {
        let value: ContractCostType = .valSer
        XCTAssertEqual(try value.toXdrJson(), "\"val_ser\"",
                       "ContractCostType.valSer must render as val_ser")
        XCTAssertEqual(value.rawValue, Int32(6),
                       "ContractCostType.valSer must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"val_ser\""), value,
                       "val_ser must read back as ContractCostType.valSer")
    }

    func test_ContractCostType_VerifyEcdsaSecp256r1Sig() throws {
        let value: ContractCostType = .verifyEcdsaSecp256r1Sig
        XCTAssertEqual(try value.toXdrJson(), "\"verify_ecdsa_secp256r1_sig\"",
                       "ContractCostType.verifyEcdsaSecp256r1Sig must render as verify_ecdsa_secp256r1_sig")
        XCTAssertEqual(value.rawValue, Int32(44),
                       "ContractCostType.verifyEcdsaSecp256r1Sig must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"verify_ecdsa_secp256r1_sig\""), value,
                       "verify_ecdsa_secp256r1_sig must read back as ContractCostType.verifyEcdsaSecp256r1Sig")
    }

    func test_ContractCostType_VerifyEd25519Sig() throws {
        let value: ContractCostType = .verifyEd25519Sig
        XCTAssertEqual(try value.toXdrJson(), "\"verify_ed25519_sig\"",
                       "ContractCostType.verifyEd25519Sig must render as verify_ed25519_sig")
        XCTAssertEqual(value.rawValue, Int32(10),
                       "ContractCostType.verifyEd25519Sig must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"verify_ed25519_sig\""), value,
                       "verify_ed25519_sig must read back as ContractCostType.verifyEd25519Sig")
    }

    func test_ContractCostType_VisitObject() throws {
        let value: ContractCostType = .visitObject
        XCTAssertEqual(try value.toXdrJson(), "\"visit_object\"",
                       "ContractCostType.visitObject must render as visit_object")
        XCTAssertEqual(value.rawValue, Int32(5),
                       "ContractCostType.visitObject must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"visit_object\""), value,
                       "visit_object must read back as ContractCostType.visitObject")
    }

    func test_ContractCostType_VmCachedInstantiation() throws {
        let value: ContractCostType = .vmCachedInstantiation
        XCTAssertEqual(try value.toXdrJson(), "\"vm_cached_instantiation\"",
                       "ContractCostType.vmCachedInstantiation must render as vm_cached_instantiation")
        XCTAssertEqual(value.rawValue, Int32(12),
                       "ContractCostType.vmCachedInstantiation must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"vm_cached_instantiation\""), value,
                       "vm_cached_instantiation must read back as ContractCostType.vmCachedInstantiation")
    }

    func test_ContractCostType_VmInstantiation() throws {
        let value: ContractCostType = .vmInstantiation
        XCTAssertEqual(try value.toXdrJson(), "\"vm_instantiation\"",
                       "ContractCostType.vmInstantiation must render as vm_instantiation")
        XCTAssertEqual(value.rawValue, Int32(11),
                       "ContractCostType.vmInstantiation must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"vm_instantiation\""), value,
                       "vm_instantiation must read back as ContractCostType.vmInstantiation")
    }

    func test_ContractCostType_WasmInsnExec() throws {
        let value: ContractCostType = .wasmInsnExec
        XCTAssertEqual(try value.toXdrJson(), "\"wasm_insn_exec\"",
                       "ContractCostType.wasmInsnExec must render as wasm_insn_exec")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ContractCostType.wasmInsnExec must keep its XDR value")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"wasm_insn_exec\""), value,
                       "wasm_insn_exec must read back as ContractCostType.wasmInsnExec")
    }

    func test_ContractCostType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ContractCostType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ContractCostType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ContractCostType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_EncodedLedgerKeyXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try EncodedLedgerKeyXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "EncodedLedgerKeyXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_EncodedLedgerKeyXDR_roundTrip() throws {
        let original: EncodedLedgerKeyXDR = Data([0x01, 0x02, 0x03])
        let tree = try EncodedLedgerKeyXDRJsonCodec.toXdrJsonValue(original)
        let json = try EncodedLedgerKeyXDRJsonCodec.toXdrJson(original)
        let decoded = try EncodedLedgerKeyXDRJsonCodec.fromXdrJson(json)
        let viaValue = try EncodedLedgerKeyXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try EncodedLedgerKeyXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try EncodedLedgerKeyXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "EncodedLedgerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try EncodedLedgerKeyXDRJsonCodec.toXdrJson(decoded), json,
                       "EncodedLedgerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try EncodedLedgerKeyXDRJsonCodec.toXdrJson(viaValue), json,
                       "EncodedLedgerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try EncodedLedgerKeyXDRJsonCodec.toXdrJson(viaTree), json,
                       "EncodedLedgerKeyXDR must read a depth-checked tree the same way")
    }

    func test_EvictionIteratorXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try EvictionIteratorXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "EvictionIteratorXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_EvictionIteratorXDR_roundTrip() throws {
        let original: EvictionIteratorXDR = EvictionIteratorXDR(bucketListLevel: UInt32(42), isCurrBucket: true, bucketFileOffset: UInt64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try EvictionIteratorXDR.fromXdrJson(json)
        let viaValue = try EvictionIteratorXDR.fromXdrJsonValue(tree)
        let viaTree = try EvictionIteratorXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "EvictionIteratorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "EvictionIteratorXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "EvictionIteratorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "EvictionIteratorXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "EvictionIteratorXDR must reach the same bytes through JSON and XDR")
    }

    func test_FreezeBypassTxsDeltaXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try FreezeBypassTxsDeltaXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "FreezeBypassTxsDeltaXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_FreezeBypassTxsDeltaXDR_roundTrip() throws {
        let original: FreezeBypassTxsDeltaXDR = FreezeBypassTxsDeltaXDR(addTxs: [WrappedData32(Data(repeating: 0xAB, count: 32))], removeTxs: [WrappedData32(Data(repeating: 0xAB, count: 32))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try FreezeBypassTxsDeltaXDR.fromXdrJson(json)
        let viaValue = try FreezeBypassTxsDeltaXDR.fromXdrJsonValue(tree)
        let viaTree = try FreezeBypassTxsDeltaXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "FreezeBypassTxsDeltaXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "FreezeBypassTxsDeltaXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "FreezeBypassTxsDeltaXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "FreezeBypassTxsDeltaXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "FreezeBypassTxsDeltaXDR must reach the same bytes through JSON and XDR")
    }

    func test_FreezeBypassTxsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try FreezeBypassTxsXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "FreezeBypassTxsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_FreezeBypassTxsXDR_roundTrip() throws {
        let original: FreezeBypassTxsXDR = FreezeBypassTxsXDR(txHashes: [WrappedData32(Data(repeating: 0xAB, count: 32))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try FreezeBypassTxsXDR.fromXdrJson(json)
        let viaValue = try FreezeBypassTxsXDR.fromXdrJsonValue(tree)
        let viaTree = try FreezeBypassTxsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "FreezeBypassTxsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "FreezeBypassTxsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "FreezeBypassTxsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "FreezeBypassTxsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "FreezeBypassTxsXDR must reach the same bytes through JSON and XDR")
    }

    func test_FrozenLedgerKeysDeltaXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try FrozenLedgerKeysDeltaXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "FrozenLedgerKeysDeltaXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_FrozenLedgerKeysDeltaXDR_roundTrip() throws {
        let original: FrozenLedgerKeysDeltaXDR = FrozenLedgerKeysDeltaXDR(keysToFreeze: [Data([0x01, 0x02, 0x03])], keysToUnfreeze: [Data([0x01, 0x02, 0x03])])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try FrozenLedgerKeysDeltaXDR.fromXdrJson(json)
        let viaValue = try FrozenLedgerKeysDeltaXDR.fromXdrJsonValue(tree)
        let viaTree = try FrozenLedgerKeysDeltaXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "FrozenLedgerKeysDeltaXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "FrozenLedgerKeysDeltaXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "FrozenLedgerKeysDeltaXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "FrozenLedgerKeysDeltaXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "FrozenLedgerKeysDeltaXDR must reach the same bytes through JSON and XDR")
    }

    func test_FrozenLedgerKeysXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try FrozenLedgerKeysXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "FrozenLedgerKeysXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_FrozenLedgerKeysXDR_roundTrip() throws {
        let original: FrozenLedgerKeysXDR = FrozenLedgerKeysXDR(keys: [Data([0x01, 0x02, 0x03])])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try FrozenLedgerKeysXDR.fromXdrJson(json)
        let viaValue = try FrozenLedgerKeysXDR.fromXdrJsonValue(tree)
        let viaTree = try FrozenLedgerKeysXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "FrozenLedgerKeysXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "FrozenLedgerKeysXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "FrozenLedgerKeysXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "FrozenLedgerKeysXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "FrozenLedgerKeysXDR must reach the same bytes through JSON and XDR")
    }

    func test_StateArchivalSettingsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try StateArchivalSettingsXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "StateArchivalSettingsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_StateArchivalSettingsXDR_roundTrip() throws {
        let original: StateArchivalSettingsXDR = StateArchivalSettingsXDR(maxEntryTTL: UInt32(42), minTemporaryTTL: UInt32(42), minPersistentTTL: UInt32(42), persistentRentRateDenominator: Int64(1234567), tempRentRateDenominator: Int64(1234567), maxEntriesToArchive: UInt32(42), liveSorobanStateSizeWindowSampleSize: UInt32(42), liveSorobanStateSizeWindowSamplePeriod: UInt32(42), evictionScanSize: UInt32(42), startingEvictionScanLevel: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StateArchivalSettingsXDR.fromXdrJson(json)
        let viaValue = try StateArchivalSettingsXDR.fromXdrJsonValue(tree)
        let viaTree = try StateArchivalSettingsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StateArchivalSettingsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StateArchivalSettingsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StateArchivalSettingsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StateArchivalSettingsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StateArchivalSettingsXDR must reach the same bytes through JSON and XDR")
    }
}
