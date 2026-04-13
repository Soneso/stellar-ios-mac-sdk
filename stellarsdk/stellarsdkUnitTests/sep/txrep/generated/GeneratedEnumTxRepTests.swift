//
// GENERATED FILE - DO NOT EDIT
//
// This file was produced by tools/xdr-generator/test/generate_tests.rb.
// It emits TxRep roundtrip tests for every XDR type registered in
// TxRepTypes.TXREP_XDR_NAMES. To regenerate, run:
//
//     make xdr-generate-tests
//
// Any manual edits will be overwritten on the next run.
//

import XCTest
import stellarsdk

final class GeneratedEnumTxRepTests: XCTestCase {

// Parse TxRep lines ("key: value") into a key->value dictionary.
//
// Lines are written by the generated toTxRep methods with the format
// "<key>: <value>". We split on the first ": " occurrence so values
// that embed colons (rare, e.g. escaped strings) round-trip intact.
static func parseTxRepLines(_ lines: [String]) -> [String: String] {
    var map: [String: String] = [:]
    for line in lines {
        if let range = line.range(of: ": ") {
            let key = String(line[..<range.lowerBound])
            let value = String(line[range.upperBound...])
            map[key] = value
        } else {
            map[line] = ""
        }
    }
    return map
}

    func test_AssetType_ASSET_TYPE_CREDIT_ALPHANUM12() throws {
        let original: AssetType = .creditAlphanum12
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try AssetType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for AssetType.creditAlphanum12")
    }

    func test_AssetType_ASSET_TYPE_CREDIT_ALPHANUM4() throws {
        let original: AssetType = .creditAlphanum4
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try AssetType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for AssetType.creditAlphanum4")
    }

    func test_AssetType_ASSET_TYPE_NATIVE() throws {
        let original: AssetType = .native
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try AssetType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for AssetType.native")
    }

    func test_AssetType_ASSET_TYPE_POOL_SHARE() throws {
        let original: AssetType = .poolShare
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try AssetType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for AssetType.poolShare")
    }

    func test_ClaimPredicateType_CLAIM_PREDICATE_AND() throws {
        let original: ClaimPredicateType = .claimPredicateAnd
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ClaimPredicateType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ClaimPredicateType.claimPredicateAnd")
    }

    func test_ClaimPredicateType_CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME() throws {
        let original: ClaimPredicateType = .claimPredicateBeforeAbsTime
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ClaimPredicateType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ClaimPredicateType.claimPredicateBeforeAbsTime")
    }

    func test_ClaimPredicateType_CLAIM_PREDICATE_BEFORE_RELATIVE_TIME() throws {
        let original: ClaimPredicateType = .claimPredicateBeforeRelTime
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ClaimPredicateType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ClaimPredicateType.claimPredicateBeforeRelTime")
    }

    func test_ClaimPredicateType_CLAIM_PREDICATE_NOT() throws {
        let original: ClaimPredicateType = .claimPredicateNot
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ClaimPredicateType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ClaimPredicateType.claimPredicateNot")
    }

    func test_ClaimPredicateType_CLAIM_PREDICATE_OR() throws {
        let original: ClaimPredicateType = .claimPredicateOr
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ClaimPredicateType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ClaimPredicateType.claimPredicateOr")
    }

    func test_ClaimPredicateType_CLAIM_PREDICATE_UNCONDITIONAL() throws {
        let original: ClaimPredicateType = .claimPredicateUnconditional
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ClaimPredicateType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ClaimPredicateType.claimPredicateUnconditional")
    }

    func test_ClaimableBalanceIDType_CLAIMABLE_BALANCE_ID_TYPE_V0() throws {
        let original: ClaimableBalanceIDType = .claimableBalanceIDTypeV0
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ClaimableBalanceIDType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ClaimableBalanceIDType.claimableBalanceIDTypeV0")
    }

    func test_ClaimantType_CLAIMANT_TYPE_V0() throws {
        let original: ClaimantType = .claimantTypeV0
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ClaimantType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ClaimantType.claimantTypeV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_BANDWIDTH_V0() throws {
        let original: ConfigSettingID = .contractBandwidthV0
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.contractBandwidthV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_COMPUTE_V0() throws {
        let original: ConfigSettingID = .contractComputeV0
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.contractComputeV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS() throws {
        let original: ConfigSettingID = .contractCostParamsCpuInstructions
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.contractCostParamsCpuInstructions")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES() throws {
        let original: ConfigSettingID = .contractCostParamsMemoryBytes
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.contractCostParamsMemoryBytes")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES() throws {
        let original: ConfigSettingID = .contractDataEntrySizeBytes
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.contractDataEntrySizeBytes")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES() throws {
        let original: ConfigSettingID = .contractDataKeySizeBytes
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.contractDataKeySizeBytes")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_EVENTS_V0() throws {
        let original: ConfigSettingID = .contractEventsV0
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.contractEventsV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_EXECUTION_LANES() throws {
        let original: ConfigSettingID = .contractExecutionLanes
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.contractExecutionLanes")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0() throws {
        let original: ConfigSettingID = .contractHistoricalDataV0
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.contractHistoricalDataV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0() throws {
        let original: ConfigSettingID = .contractLedgerCostExtV0
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.contractLedgerCostExtV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_LEDGER_COST_V0() throws {
        let original: ConfigSettingID = .contractLedgerCostV0
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.contractLedgerCostV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES() throws {
        let original: ConfigSettingID = .contractMaxSizeBytes
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.contractMaxSizeBytes")
    }

    func test_ConfigSettingID_CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0() throws {
        let original: ConfigSettingID = .contractParallelComputeV0
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.contractParallelComputeV0")
    }

    func test_ConfigSettingID_CONFIG_SETTING_EVICTION_ITERATOR() throws {
        let original: ConfigSettingID = .evictionIterator
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.evictionIterator")
    }

    func test_ConfigSettingID_CONFIG_SETTING_FREEZE_BYPASS_TXS() throws {
        let original: ConfigSettingID = .freezeBypassTxs
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.freezeBypassTxs")
    }

    func test_ConfigSettingID_CONFIG_SETTING_FREEZE_BYPASS_TXS_DELTA() throws {
        let original: ConfigSettingID = .freezeBypassTxsDelta
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.freezeBypassTxsDelta")
    }

    func test_ConfigSettingID_CONFIG_SETTING_FROZEN_LEDGER_KEYS() throws {
        let original: ConfigSettingID = .frozenLedgerKeys
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.frozenLedgerKeys")
    }

    func test_ConfigSettingID_CONFIG_SETTING_FROZEN_LEDGER_KEYS_DELTA() throws {
        let original: ConfigSettingID = .frozenLedgerKeysDelta
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.frozenLedgerKeysDelta")
    }

    func test_ConfigSettingID_CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW() throws {
        let original: ConfigSettingID = .liveSorobanStateSizeWindow
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.liveSorobanStateSizeWindow")
    }

    func test_ConfigSettingID_CONFIG_SETTING_SCP_TIMING() throws {
        let original: ConfigSettingID = .scpTiming
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.scpTiming")
    }

    func test_ConfigSettingID_CONFIG_SETTING_STATE_ARCHIVAL() throws {
        let original: ConfigSettingID = .stateArchival
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ConfigSettingID.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ConfigSettingID.stateArchival")
    }

    func test_ContractDataDurability_PERSISTENT() throws {
        let original: ContractDataDurability = .persistent
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ContractDataDurability.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ContractDataDurability.persistent")
    }

    func test_ContractDataDurability_TEMPORARY() throws {
        let original: ContractDataDurability = .temporary
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ContractDataDurability.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ContractDataDurability.temporary")
    }

    func test_ContractExecutableType_CONTRACT_EXECUTABLE_STELLAR_ASSET() throws {
        let original: ContractExecutableType = .stellarAsset
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ContractExecutableType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ContractExecutableType.stellarAsset")
    }

    func test_ContractExecutableType_CONTRACT_EXECUTABLE_WASM() throws {
        let original: ContractExecutableType = .wasm
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ContractExecutableType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ContractExecutableType.wasm")
    }

    func test_ContractIDPreimageType_CONTRACT_ID_PREIMAGE_FROM_ADDRESS() throws {
        let original: ContractIDPreimageType = .fromAddress
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ContractIDPreimageType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ContractIDPreimageType.fromAddress")
    }

    func test_ContractIDPreimageType_CONTRACT_ID_PREIMAGE_FROM_ASSET() throws {
        let original: ContractIDPreimageType = .fromAsset
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try ContractIDPreimageType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for ContractIDPreimageType.fromAsset")
    }

    func test_CryptoKeyType_KEY_TYPE_ED25519() throws {
        let original: CryptoKeyType = .ed25519
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try CryptoKeyType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for CryptoKeyType.ed25519")
    }

    func test_CryptoKeyType_KEY_TYPE_ED25519_SIGNED_PAYLOAD() throws {
        let original: CryptoKeyType = .ed25519SignedPayload
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try CryptoKeyType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for CryptoKeyType.ed25519SignedPayload")
    }

    func test_CryptoKeyType_KEY_TYPE_HASH_X() throws {
        let original: CryptoKeyType = .hashX
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try CryptoKeyType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for CryptoKeyType.hashX")
    }

    func test_CryptoKeyType_KEY_TYPE_MUXED_ED25519() throws {
        let original: CryptoKeyType = .muxedEd25519
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try CryptoKeyType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for CryptoKeyType.muxedEd25519")
    }

    func test_CryptoKeyType_KEY_TYPE_PRE_AUTH_TX() throws {
        let original: CryptoKeyType = .preAuthTx
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try CryptoKeyType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for CryptoKeyType.preAuthTx")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_AUTH() throws {
        let original: EnvelopeType = .auth
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try EnvelopeType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for EnvelopeType.auth")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_CONTRACT_ID() throws {
        let original: EnvelopeType = .contractId
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try EnvelopeType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for EnvelopeType.contractId")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_OP_ID() throws {
        let original: EnvelopeType = .opId
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try EnvelopeType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for EnvelopeType.opId")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_POOL_REVOKE_OP_ID() throws {
        let original: EnvelopeType = .poolRevokeOpId
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try EnvelopeType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for EnvelopeType.poolRevokeOpId")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_SCP() throws {
        let original: EnvelopeType = .scp
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try EnvelopeType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for EnvelopeType.scp")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_SCPVALUE() throws {
        let original: EnvelopeType = .scpvalue
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try EnvelopeType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for EnvelopeType.scpvalue")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_SOROBAN_AUTHORIZATION() throws {
        let original: EnvelopeType = .sorobanAuthorization
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try EnvelopeType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for EnvelopeType.sorobanAuthorization")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_TX() throws {
        let original: EnvelopeType = .tx
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try EnvelopeType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for EnvelopeType.tx")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_TX_FEE_BUMP() throws {
        let original: EnvelopeType = .txFeeBump
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try EnvelopeType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for EnvelopeType.txFeeBump")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_TX_V0() throws {
        let original: EnvelopeType = .txV0
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try EnvelopeType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for EnvelopeType.txV0")
    }

    func test_HostFunctionType_HOST_FUNCTION_TYPE_CREATE_CONTRACT() throws {
        let original: HostFunctionType = .createContract
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try HostFunctionType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for HostFunctionType.createContract")
    }

    func test_HostFunctionType_HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2() throws {
        let original: HostFunctionType = .createContractV2
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try HostFunctionType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for HostFunctionType.createContractV2")
    }

    func test_HostFunctionType_HOST_FUNCTION_TYPE_INVOKE_CONTRACT() throws {
        let original: HostFunctionType = .invokeContract
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try HostFunctionType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for HostFunctionType.invokeContract")
    }

    func test_HostFunctionType_HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM() throws {
        let original: HostFunctionType = .uploadContractWasm
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try HostFunctionType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for HostFunctionType.uploadContractWasm")
    }

    func test_LedgerEntryType_ACCOUNT() throws {
        let original: LedgerEntryType = .account
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try LedgerEntryType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for LedgerEntryType.account")
    }

    func test_LedgerEntryType_CLAIMABLE_BALANCE() throws {
        let original: LedgerEntryType = .claimableBalance
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try LedgerEntryType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for LedgerEntryType.claimableBalance")
    }

    func test_LedgerEntryType_CONFIG_SETTING() throws {
        let original: LedgerEntryType = .configSetting
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try LedgerEntryType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for LedgerEntryType.configSetting")
    }

    func test_LedgerEntryType_CONTRACT_CODE() throws {
        let original: LedgerEntryType = .contractCode
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try LedgerEntryType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for LedgerEntryType.contractCode")
    }

    func test_LedgerEntryType_CONTRACT_DATA() throws {
        let original: LedgerEntryType = .contractData
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try LedgerEntryType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for LedgerEntryType.contractData")
    }

    func test_LedgerEntryType_DATA() throws {
        let original: LedgerEntryType = .data
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try LedgerEntryType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for LedgerEntryType.data")
    }

    func test_LedgerEntryType_LIQUIDITY_POOL() throws {
        let original: LedgerEntryType = .liquidityPool
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try LedgerEntryType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for LedgerEntryType.liquidityPool")
    }

    func test_LedgerEntryType_OFFER() throws {
        let original: LedgerEntryType = .offer
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try LedgerEntryType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for LedgerEntryType.offer")
    }

    func test_LedgerEntryType_TRUSTLINE() throws {
        let original: LedgerEntryType = .trustline
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try LedgerEntryType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for LedgerEntryType.trustline")
    }

    func test_LedgerEntryType_TTL() throws {
        let original: LedgerEntryType = .ttl
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try LedgerEntryType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for LedgerEntryType.ttl")
    }

    func test_LiquidityPoolType_LIQUIDITY_POOL_CONSTANT_PRODUCT() throws {
        let original: LiquidityPoolType = .constantProduct
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try LiquidityPoolType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for LiquidityPoolType.constantProduct")
    }

    func test_MemoType_MEMO_HASH() throws {
        let original: MemoType = .MEMO_TYPE_HASH
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try MemoType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for MemoType.MEMO_TYPE_HASH")
    }

    func test_MemoType_MEMO_ID() throws {
        let original: MemoType = .MEMO_TYPE_ID
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try MemoType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for MemoType.MEMO_TYPE_ID")
    }

    func test_MemoType_MEMO_NONE() throws {
        let original: MemoType = .MEMO_TYPE_NONE
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try MemoType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for MemoType.MEMO_TYPE_NONE")
    }

    func test_MemoType_MEMO_RETURN() throws {
        let original: MemoType = .MEMO_TYPE_RETURN
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try MemoType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for MemoType.MEMO_TYPE_RETURN")
    }

    func test_MemoType_MEMO_TEXT() throws {
        let original: MemoType = .MEMO_TYPE_TEXT
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try MemoType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for MemoType.MEMO_TYPE_TEXT")
    }

    func test_OperationType_ACCOUNT_MERGE() throws {
        let original: OperationType = .accountMerge
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.accountMerge")
    }

    func test_OperationType_ALLOW_TRUST() throws {
        let original: OperationType = .allowTrust
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.allowTrust")
    }

    func test_OperationType_BEGIN_SPONSORING_FUTURE_RESERVES() throws {
        let original: OperationType = .beginSponsoringFutureReserves
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.beginSponsoringFutureReserves")
    }

    func test_OperationType_BUMP_SEQUENCE() throws {
        let original: OperationType = .bumpSequence
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.bumpSequence")
    }

    func test_OperationType_CHANGE_TRUST() throws {
        let original: OperationType = .changeTrust
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.changeTrust")
    }

    func test_OperationType_CLAIM_CLAIMABLE_BALANCE() throws {
        let original: OperationType = .claimClaimableBalance
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.claimClaimableBalance")
    }

    func test_OperationType_CLAWBACK() throws {
        let original: OperationType = .clawback
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.clawback")
    }

    func test_OperationType_CLAWBACK_CLAIMABLE_BALANCE() throws {
        let original: OperationType = .clawbackClaimableBalance
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.clawbackClaimableBalance")
    }

    func test_OperationType_CREATE_ACCOUNT() throws {
        let original: OperationType = .accountCreated
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.accountCreated")
    }

    func test_OperationType_CREATE_CLAIMABLE_BALANCE() throws {
        let original: OperationType = .createClaimableBalance
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.createClaimableBalance")
    }

    func test_OperationType_CREATE_PASSIVE_SELL_OFFER() throws {
        let original: OperationType = .createPassiveSellOffer
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.createPassiveSellOffer")
    }

    func test_OperationType_END_SPONSORING_FUTURE_RESERVES() throws {
        let original: OperationType = .endSponsoringFutureReserves
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.endSponsoringFutureReserves")
    }

    func test_OperationType_EXTEND_FOOTPRINT_TTL() throws {
        let original: OperationType = .extendFootprintTTL
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.extendFootprintTTL")
    }

    func test_OperationType_INFLATION() throws {
        let original: OperationType = .inflation
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.inflation")
    }

    func test_OperationType_INVOKE_HOST_FUNCTION() throws {
        let original: OperationType = .invokeHostFunction
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.invokeHostFunction")
    }

    func test_OperationType_LIQUIDITY_POOL_DEPOSIT() throws {
        let original: OperationType = .liquidityPoolDeposit
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.liquidityPoolDeposit")
    }

    func test_OperationType_LIQUIDITY_POOL_WITHDRAW() throws {
        let original: OperationType = .liquidityPoolWithdraw
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.liquidityPoolWithdraw")
    }

    func test_OperationType_MANAGE_BUY_OFFER() throws {
        let original: OperationType = .manageBuyOffer
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.manageBuyOffer")
    }

    func test_OperationType_MANAGE_DATA() throws {
        let original: OperationType = .manageData
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.manageData")
    }

    func test_OperationType_MANAGE_SELL_OFFER() throws {
        let original: OperationType = .manageSellOffer
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.manageSellOffer")
    }

    func test_OperationType_PATH_PAYMENT_STRICT_RECEIVE() throws {
        let original: OperationType = .pathPayment
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.pathPayment")
    }

    func test_OperationType_PATH_PAYMENT_STRICT_SEND() throws {
        let original: OperationType = .pathPaymentStrictSend
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.pathPaymentStrictSend")
    }

    func test_OperationType_PAYMENT() throws {
        let original: OperationType = .payment
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.payment")
    }

    func test_OperationType_RESTORE_FOOTPRINT() throws {
        let original: OperationType = .restoreFootprint
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.restoreFootprint")
    }

    func test_OperationType_REVOKE_SPONSORSHIP() throws {
        let original: OperationType = .revokeSponsorship
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.revokeSponsorship")
    }

    func test_OperationType_SET_OPTIONS() throws {
        let original: OperationType = .setOptions
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.setOptions")
    }

    func test_OperationType_SET_TRUST_LINE_FLAGS() throws {
        let original: OperationType = .setTrustLineFlags
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try OperationType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for OperationType.setTrustLineFlags")
    }

    func test_PreconditionType_PRECOND_NONE() throws {
        let original: PreconditionType = .none
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try PreconditionType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for PreconditionType.none")
    }

    func test_PreconditionType_PRECOND_TIME() throws {
        let original: PreconditionType = .time
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try PreconditionType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for PreconditionType.time")
    }

    func test_PreconditionType_PRECOND_V2() throws {
        let original: PreconditionType = .v2
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try PreconditionType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for PreconditionType.v2")
    }

    func test_PublicKeyTypeXDR_PUBLIC_KEY_TYPE_ED25519() throws {
        let original: PublicKeyTypeXDR = .publicKeyTypeEd25519
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try PublicKeyTypeXDR.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for PublicKeyTypeXDR.publicKeyTypeEd25519")
    }

    func test_RevokeSponsorshipType_REVOKE_SPONSORSHIP_LEDGER_ENTRY() throws {
        let original: RevokeSponsorshipType = .revokeSponsorshipLedgerEntry
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try RevokeSponsorshipType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for RevokeSponsorshipType.revokeSponsorshipLedgerEntry")
    }

    func test_RevokeSponsorshipType_REVOKE_SPONSORSHIP_SIGNER() throws {
        let original: RevokeSponsorshipType = .revokeSponsorshipSignerEntry
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try RevokeSponsorshipType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for RevokeSponsorshipType.revokeSponsorshipSignerEntry")
    }

    func test_SCAddressType_SC_ADDRESS_TYPE_ACCOUNT() throws {
        let original: SCAddressType = .account
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCAddressType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCAddressType.account")
    }

    func test_SCAddressType_SC_ADDRESS_TYPE_CLAIMABLE_BALANCE() throws {
        let original: SCAddressType = .claimableBalance
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCAddressType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCAddressType.claimableBalance")
    }

    func test_SCAddressType_SC_ADDRESS_TYPE_CONTRACT() throws {
        let original: SCAddressType = .contract
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCAddressType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCAddressType.contract")
    }

    func test_SCAddressType_SC_ADDRESS_TYPE_LIQUIDITY_POOL() throws {
        let original: SCAddressType = .liquidityPool
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCAddressType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCAddressType.liquidityPool")
    }

    func test_SCAddressType_SC_ADDRESS_TYPE_MUXED_ACCOUNT() throws {
        let original: SCAddressType = .muxedAccount
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCAddressType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCAddressType.muxedAccount")
    }

    func test_SCErrorCode_SCEC_ARITH_DOMAIN() throws {
        let original: SCErrorCode = .arithDomain
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorCode.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorCode.arithDomain")
    }

    func test_SCErrorCode_SCEC_EXCEEDED_LIMIT() throws {
        let original: SCErrorCode = .exceededLimit
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorCode.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorCode.exceededLimit")
    }

    func test_SCErrorCode_SCEC_EXISTING_VALUE() throws {
        let original: SCErrorCode = .existingValue
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorCode.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorCode.existingValue")
    }

    func test_SCErrorCode_SCEC_INDEX_BOUNDS() throws {
        let original: SCErrorCode = .indexBounds
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorCode.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorCode.indexBounds")
    }

    func test_SCErrorCode_SCEC_INTERNAL_ERROR() throws {
        let original: SCErrorCode = .internalError
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorCode.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorCode.internalError")
    }

    func test_SCErrorCode_SCEC_INVALID_ACTION() throws {
        let original: SCErrorCode = .invalidAction
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorCode.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorCode.invalidAction")
    }

    func test_SCErrorCode_SCEC_INVALID_INPUT() throws {
        let original: SCErrorCode = .invalidInput
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorCode.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorCode.invalidInput")
    }

    func test_SCErrorCode_SCEC_MISSING_VALUE() throws {
        let original: SCErrorCode = .missingValue
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorCode.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorCode.missingValue")
    }

    func test_SCErrorCode_SCEC_UNEXPECTED_SIZE() throws {
        let original: SCErrorCode = .unexpectedSize
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorCode.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorCode.unexpectedSize")
    }

    func test_SCErrorCode_SCEC_UNEXPECTED_TYPE() throws {
        let original: SCErrorCode = .unexpectedType
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorCode.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorCode.unexpectedType")
    }

    func test_SCErrorType_SCE_AUTH() throws {
        let original: SCErrorType = .auth
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorType.auth")
    }

    func test_SCErrorType_SCE_BUDGET() throws {
        let original: SCErrorType = .budget
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorType.budget")
    }

    func test_SCErrorType_SCE_CONTEXT() throws {
        let original: SCErrorType = .context
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorType.context")
    }

    func test_SCErrorType_SCE_CONTRACT() throws {
        let original: SCErrorType = .contract
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorType.contract")
    }

    func test_SCErrorType_SCE_CRYPTO() throws {
        let original: SCErrorType = .crypto
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorType.crypto")
    }

    func test_SCErrorType_SCE_EVENTS() throws {
        let original: SCErrorType = .events
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorType.events")
    }

    func test_SCErrorType_SCE_OBJECT() throws {
        let original: SCErrorType = .object
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorType.object")
    }

    func test_SCErrorType_SCE_STORAGE() throws {
        let original: SCErrorType = .storage
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorType.storage")
    }

    func test_SCErrorType_SCE_VALUE() throws {
        let original: SCErrorType = .value
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorType.value")
    }

    func test_SCErrorType_SCE_WASM_VM() throws {
        let original: SCErrorType = .wasmVm
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCErrorType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCErrorType.wasmVm")
    }

    func test_SCValType_SCV_ADDRESS() throws {
        let original: SCValType = .address
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.address")
    }

    func test_SCValType_SCV_BOOL() throws {
        let original: SCValType = .bool
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.bool")
    }

    func test_SCValType_SCV_BYTES() throws {
        let original: SCValType = .bytes
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.bytes")
    }

    func test_SCValType_SCV_CONTRACT_INSTANCE() throws {
        let original: SCValType = .contractInstance
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.contractInstance")
    }

    func test_SCValType_SCV_DURATION() throws {
        let original: SCValType = .duration
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.duration")
    }

    func test_SCValType_SCV_ERROR() throws {
        let original: SCValType = .error
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.error")
    }

    func test_SCValType_SCV_I128() throws {
        let original: SCValType = .i128
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.i128")
    }

    func test_SCValType_SCV_I256() throws {
        let original: SCValType = .i256
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.i256")
    }

    func test_SCValType_SCV_I32() throws {
        let original: SCValType = .i32
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.i32")
    }

    func test_SCValType_SCV_I64() throws {
        let original: SCValType = .i64
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.i64")
    }

    func test_SCValType_SCV_LEDGER_KEY_CONTRACT_INSTANCE() throws {
        let original: SCValType = .ledgerKeyContractInstance
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.ledgerKeyContractInstance")
    }

    func test_SCValType_SCV_LEDGER_KEY_NONCE() throws {
        let original: SCValType = .ledgerKeyNonce
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.ledgerKeyNonce")
    }

    func test_SCValType_SCV_MAP() throws {
        let original: SCValType = .map
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.map")
    }

    func test_SCValType_SCV_STRING() throws {
        let original: SCValType = .string
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.string")
    }

    func test_SCValType_SCV_SYMBOL() throws {
        let original: SCValType = .symbol
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.symbol")
    }

    func test_SCValType_SCV_TIMEPOINT() throws {
        let original: SCValType = .timepoint
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.timepoint")
    }

    func test_SCValType_SCV_U128() throws {
        let original: SCValType = .u128
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.u128")
    }

    func test_SCValType_SCV_U256() throws {
        let original: SCValType = .u256
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.u256")
    }

    func test_SCValType_SCV_U32() throws {
        let original: SCValType = .u32
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.u32")
    }

    func test_SCValType_SCV_U64() throws {
        let original: SCValType = .u64
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.u64")
    }

    func test_SCValType_SCV_VEC() throws {
        let original: SCValType = .vec
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.vec")
    }

    func test_SCValType_SCV_VOID() throws {
        let original: SCValType = .void
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SCValType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SCValType.void")
    }

    func test_SignerKeyType_SIGNER_KEY_TYPE_ED25519() throws {
        let original: SignerKeyType = .ed25519
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SignerKeyType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SignerKeyType.ed25519")
    }

    func test_SignerKeyType_SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD() throws {
        let original: SignerKeyType = .signedPayload
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SignerKeyType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SignerKeyType.signedPayload")
    }

    func test_SignerKeyType_SIGNER_KEY_TYPE_HASH_X() throws {
        let original: SignerKeyType = .hashX
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SignerKeyType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SignerKeyType.hashX")
    }

    func test_SignerKeyType_SIGNER_KEY_TYPE_PRE_AUTH_TX() throws {
        let original: SignerKeyType = .preAuthTx
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SignerKeyType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SignerKeyType.preAuthTx")
    }

    func test_SorobanAuthorizedFunctionType_SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN() throws {
        let original: SorobanAuthorizedFunctionType = .contractFn
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SorobanAuthorizedFunctionType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SorobanAuthorizedFunctionType.contractFn")
    }

    func test_SorobanAuthorizedFunctionType_SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN() throws {
        let original: SorobanAuthorizedFunctionType = .createContractHostFn
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SorobanAuthorizedFunctionType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SorobanAuthorizedFunctionType.createContractHostFn")
    }

    func test_SorobanAuthorizedFunctionType_SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN() throws {
        let original: SorobanAuthorizedFunctionType = .createContractV2HostFn
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SorobanAuthorizedFunctionType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SorobanAuthorizedFunctionType.createContractV2HostFn")
    }

    func test_SorobanCredentialsType_SOROBAN_CREDENTIALS_ADDRESS() throws {
        let original: SorobanCredentialsType = .address
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SorobanCredentialsType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SorobanCredentialsType.address")
    }

    func test_SorobanCredentialsType_SOROBAN_CREDENTIALS_SOURCE_ACCOUNT() throws {
        let original: SorobanCredentialsType = .sourceAccount
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let decoded = try SorobanCredentialsType.fromTxRep(map, prefix: "k")
        XCTAssertEqual(decoded, original, "TxRep roundtrip failed for SorobanCredentialsType.sourceAccount")
    }

}
