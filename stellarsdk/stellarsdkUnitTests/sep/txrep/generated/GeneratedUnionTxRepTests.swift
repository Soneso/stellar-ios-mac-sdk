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

final class GeneratedUnionTxRepTests: XCTestCase {

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

    func test_AssetXDR_alphanum12() throws {
        let original: AssetXDR = .alphanum12(Alpha12XDR(assetCode: WrappedData12(Data([0x55, 0x53, 0x44, 0x43, 0x54, 0x4f, 0x4b, 0x45, 0x4e, 0x00, 0x00, 0x00])), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try AssetXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for AssetXDR.alphanum12")
    }

    func test_AssetXDR_alphanum4() throws {
        let original: AssetXDR = .alphanum4(Alpha4XDR(assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try AssetXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for AssetXDR.alphanum4")
    }

    func test_AssetXDR_native() throws {
        let original: AssetXDR = .native
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try AssetXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for AssetXDR.native")
    }

    func test_ChangeTrustAssetXDR_alphanum12() throws {
        let original: ChangeTrustAssetXDR = .alphanum12(Alpha12XDR(assetCode: WrappedData12(Data([0x55, 0x53, 0x44, 0x43, 0x54, 0x4f, 0x4b, 0x45, 0x4e, 0x00, 0x00, 0x00])), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ChangeTrustAssetXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ChangeTrustAssetXDR.alphanum12")
    }

    func test_ChangeTrustAssetXDR_alphanum4() throws {
        let original: ChangeTrustAssetXDR = .alphanum4(Alpha4XDR(assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ChangeTrustAssetXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ChangeTrustAssetXDR.alphanum4")
    }

    func test_ChangeTrustAssetXDR_native() throws {
        let original: ChangeTrustAssetXDR = .native
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ChangeTrustAssetXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ChangeTrustAssetXDR.native")
    }

    func test_ChangeTrustAssetXDR_poolShare() throws {
        let original: ChangeTrustAssetXDR = .poolShare(.constantProduct(LiquidityPoolConstantProductParametersXDR(assetA: .native, assetB: .native, fee: 42)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ChangeTrustAssetXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ChangeTrustAssetXDR.poolShare")
    }

    func test_ClaimPredicateXDR_claimPredicateAnd() throws {
        let original: ClaimPredicateXDR = .claimPredicateAnd([])
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ClaimPredicateXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ClaimPredicateXDR.claimPredicateAnd")
    }

    func test_ClaimPredicateXDR_claimPredicateBeforeAbsTime() throws {
        let original: ClaimPredicateXDR = .claimPredicateBeforeAbsTime(Int64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ClaimPredicateXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ClaimPredicateXDR.claimPredicateBeforeAbsTime")
    }

    func test_ClaimPredicateXDR_claimPredicateBeforeRelTime() throws {
        let original: ClaimPredicateXDR = .claimPredicateBeforeRelTime(Int64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ClaimPredicateXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ClaimPredicateXDR.claimPredicateBeforeRelTime")
    }

    func test_ClaimPredicateXDR_claimPredicateNot() throws {
        let original: ClaimPredicateXDR = .claimPredicateNot(.claimPredicateUnconditional)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ClaimPredicateXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ClaimPredicateXDR.claimPredicateNot")
    }

    func test_ClaimPredicateXDR_claimPredicateOr() throws {
        let original: ClaimPredicateXDR = .claimPredicateOr([])
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ClaimPredicateXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ClaimPredicateXDR.claimPredicateOr")
    }

    func test_ClaimPredicateXDR_claimPredicateUnconditional() throws {
        let original: ClaimPredicateXDR = .claimPredicateUnconditional
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ClaimPredicateXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ClaimPredicateXDR.claimPredicateUnconditional")
    }

    func test_ClaimableBalanceIDXDR_claimableBalanceIDTypeV0() throws {
        let original: ClaimableBalanceIDXDR = .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ClaimableBalanceIDXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ClaimableBalanceIDXDR.claimableBalanceIDTypeV0")
    }

    func test_ClaimantXDR_claimantTypeV0() throws {
        let original: ClaimantXDR = .claimantTypeV0(ClaimantV0XDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), predicate: .claimPredicateUnconditional))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ClaimantXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ClaimantXDR.claimantTypeV0")
    }

    func test_ContractExecutableXDR_token() throws {
        let original: ContractExecutableXDR = .token
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ContractExecutableXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ContractExecutableXDR.token")
    }

    func test_ContractExecutableXDR_wasm() throws {
        let original: ContractExecutableXDR = .wasm(WrappedData32(Data(repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ContractExecutableXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ContractExecutableXDR.wasm")
    }

    func test_ContractIDPreimageXDR_fromAddress() throws {
        let original: ContractIDPreimageXDR = .fromAddress(ContractIDPreimageFromAddressXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), salt: WrappedData32(Data(repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ContractIDPreimageXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ContractIDPreimageXDR.fromAddress")
    }

    func test_ContractIDPreimageXDR_fromAsset() throws {
        let original: ContractIDPreimageXDR = .fromAsset(.native)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ContractIDPreimageXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ContractIDPreimageXDR.fromAsset")
    }

    func test_ExtensionPoint_void() throws {
        let original: ExtensionPoint = .void
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ExtensionPoint.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ExtensionPoint.void")
    }

    func test_FeeBumpTransactionXDRExtXDR_void() throws {
        let original: FeeBumpTransactionXDRExtXDR = .void
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try FeeBumpTransactionXDRExtXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for FeeBumpTransactionXDRExtXDR.void")
    }

    func test_FeeBumpTransactionXDRInnerTxXDR_v1() throws {
        let original: FeeBumpTransactionXDRInnerTxXDR = .v1(TransactionV1EnvelopeXDR(tx: TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, memo: .none, operations: [], maxOperationFee: UInt32(100)), signatures: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try FeeBumpTransactionXDRInnerTxXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for FeeBumpTransactionXDRInnerTxXDR.v1")
    }

    func test_HostFunctionXDR_createContract() throws {
        let original: HostFunctionXDR = .createContract(CreateContractArgsXDR(contractIDPreimage: .fromAsset(.native), executable: .token))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try HostFunctionXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for HostFunctionXDR.createContract")
    }

    func test_HostFunctionXDR_createContractV2() throws {
        let original: HostFunctionXDR = .createContractV2(CreateContractV2ArgsXDR(contractIDPreimage: .fromAsset(.native), executable: .token, constructorArgs: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try HostFunctionXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for HostFunctionXDR.createContractV2")
    }

    func test_HostFunctionXDR_invokeContract() throws {
        let original: HostFunctionXDR = .invokeContract(InvokeContractArgsXDR(contractAddress: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), functionName: "test_string", args: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try HostFunctionXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for HostFunctionXDR.invokeContract")
    }

    func test_HostFunctionXDR_uploadContractWasm() throws {
        let original: HostFunctionXDR = .uploadContractWasm(Data([0x01, 0x02, 0x03]))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try HostFunctionXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for HostFunctionXDR.uploadContractWasm")
    }

    func test_LedgerKeyXDR_account() throws {
        let original: LedgerKeyXDR = .account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyXDR.account")
    }

    func test_LedgerKeyXDR_claimableBalance() throws {
        let original: LedgerKeyXDR = .claimableBalance(LedgerKeyClaimableBalanceXDR(balanceID: .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32)))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyXDR.claimableBalance")
    }

    func test_LedgerKeyXDR_configSetting() throws {
        let original: LedgerKeyXDR = .configSetting(LedgerKeyConfigSettingXDR(configSettingID: 42))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyXDR.configSetting")
    }

    func test_LedgerKeyXDR_contractCode() throws {
        let original: LedgerKeyXDR = .contractCode(LedgerKeyContractCodeXDR(hash: WrappedData32(Data(repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyXDR.contractCode")
    }

    func test_LedgerKeyXDR_contractData() throws {
        let original: LedgerKeyXDR = .contractData(LedgerKeyContractDataXDR(contract: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), key: .void, durability: .temporary))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyXDR.contractData")
    }

    func test_LedgerKeyXDR_data() throws {
        let original: LedgerKeyXDR = .data(LedgerKeyDataXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string"))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyXDR.data")
    }

    func test_LedgerKeyXDR_liquidityPool() throws {
        let original: LedgerKeyXDR = .liquidityPool(LedgerKeyLiquidityPoolXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyXDR.liquidityPool")
    }

    func test_LedgerKeyXDR_offer() throws {
        let original: LedgerKeyXDR = .offer(LedgerKeyOfferXDR(sellerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), offerID: Int64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyXDR.offer")
    }

    func test_LedgerKeyXDR_trustline() throws {
        let original: LedgerKeyXDR = .trustline(LedgerKeyTrustLineXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .native))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyXDR.trustline")
    }

    func test_LedgerKeyXDR_ttl() throws {
        let original: LedgerKeyXDR = .ttl(LedgerKeyTTLXDR(keyHash: WrappedData32(Data(repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyXDR.ttl")
    }

    func test_LiquidityPoolParametersXDR_constantProduct() throws {
        let original: LiquidityPoolParametersXDR = .constantProduct(LiquidityPoolConstantProductParametersXDR(assetA: .native, assetB: .native, fee: 42))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LiquidityPoolParametersXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LiquidityPoolParametersXDR.constantProduct")
    }

    func test_MemoXDR_hash() throws {
        let original: MemoXDR = .hash(WrappedData32(Data(repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try MemoXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for MemoXDR.hash")
    }

    func test_MemoXDR_id() throws {
        let original: MemoXDR = .id(UInt64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try MemoXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for MemoXDR.id")
    }

    func test_MemoXDR_none() throws {
        let original: MemoXDR = .none
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try MemoXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for MemoXDR.none")
    }

    func test_MemoXDR_returnHash() throws {
        let original: MemoXDR = .returnHash(WrappedData32(Data(repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try MemoXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for MemoXDR.returnHash")
    }

    func test_MemoXDR_text() throws {
        let original: MemoXDR = .text("test_string")
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try MemoXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for MemoXDR.text")
    }

    func test_OperationBodyXDR_accountMerge() throws {
        let original: OperationBodyXDR = .accountMerge(.ed25519([UInt8](repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.accountMerge")
    }

    func test_OperationBodyXDR_allowTrustOp() throws {
        let original: OperationBodyXDR = .allowTrustOp(AllowTrustOperationXDR(trustor: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .alphanum4(WrappedData4(Data([0x55, 0x53, 0x44, 0x00]))), authorize: UInt32(42)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.allowTrustOp")
    }

    func test_OperationBodyXDR_beginSponsoringFutureReservesOp() throws {
        let original: OperationBodyXDR = .beginSponsoringFutureReservesOp(BeginSponsoringFutureReservesOpXDR(sponsoredId: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.beginSponsoringFutureReservesOp")
    }

    func test_OperationBodyXDR_bumpSequenceOp() throws {
        let original: OperationBodyXDR = .bumpSequenceOp(BumpSequenceOperationXDR(bumpTo: Int64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.bumpSequenceOp")
    }

    func test_OperationBodyXDR_changeTrustOp() throws {
        let original: OperationBodyXDR = .changeTrustOp(ChangeTrustOperationXDR(asset: .native, limit: Int64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.changeTrustOp")
    }

    func test_OperationBodyXDR_claimClaimableBalanceOp() throws {
        let original: OperationBodyXDR = .claimClaimableBalanceOp(ClaimClaimableBalanceOpXDR(balanceID: .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32)))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.claimClaimableBalanceOp")
    }

    func test_OperationBodyXDR_clawbackClaimableBalanceOp() throws {
        let original: OperationBodyXDR = .clawbackClaimableBalanceOp(ClawbackClaimableBalanceOpXDR(claimableBalanceID: .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32)))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.clawbackClaimableBalanceOp")
    }

    func test_OperationBodyXDR_clawbackOp() throws {
        let original: OperationBodyXDR = .clawbackOp(ClawbackOpXDR(asset: .native, from: .ed25519([UInt8](repeating: 0xAB, count: 32)), amount: Int64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.clawbackOp")
    }

    func test_OperationBodyXDR_createAccountOp() throws {
        let original: OperationBodyXDR = .createAccountOp(CreateAccountOperationXDR(destination: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.createAccountOp")
    }

    func test_OperationBodyXDR_createClaimableBalanceOp() throws {
        let original: OperationBodyXDR = .createClaimableBalanceOp(CreateClaimableBalanceOpXDR(asset: .native, amount: Int64(1234567), claimants: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.createClaimableBalanceOp")
    }

    func test_OperationBodyXDR_createPassiveSellOfferOp() throws {
        let original: OperationBodyXDR = .createPassiveSellOfferOp(CreatePassiveOfferOperationXDR(selling: .native, buying: .native, amount: Int64(1234567), price: PriceXDR(n: 42, d: 42)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.createPassiveSellOfferOp")
    }

    func test_OperationBodyXDR_endSponsoringFutureReserves() throws {
        let original: OperationBodyXDR = .endSponsoringFutureReserves
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.endSponsoringFutureReserves")
    }

    func test_OperationBodyXDR_extendFootprintTTLOp() throws {
        let original: OperationBodyXDR = .extendFootprintTTLOp(ExtendFootprintTTLOpXDR(ext: .void, extendTo: UInt32(42)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.extendFootprintTTLOp")
    }

    func test_OperationBodyXDR_inflation() throws {
        let original: OperationBodyXDR = .inflation
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.inflation")
    }

    func test_OperationBodyXDR_invokeHostFunctionOp() throws {
        let original: OperationBodyXDR = .invokeHostFunctionOp(InvokeHostFunctionOpXDR(hostFunction: .uploadContractWasm(Data([0x01, 0x02, 0x03])), auth: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.invokeHostFunctionOp")
    }

    func test_OperationBodyXDR_liquidityPoolDepositOp() throws {
        let original: OperationBodyXDR = .liquidityPoolDepositOp(LiquidityPoolDepositOpXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)), maxAmountA: Int64(1234567), maxAmountB: Int64(1234567), minPrice: PriceXDR(n: 42, d: 42), maxPrice: PriceXDR(n: 42, d: 42)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.liquidityPoolDepositOp")
    }

    func test_OperationBodyXDR_liquidityPoolWithdrawOp() throws {
        let original: OperationBodyXDR = .liquidityPoolWithdrawOp(LiquidityPoolWithdrawOpXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)), amount: Int64(1234567), minAmountA: Int64(1234567), minAmountB: Int64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.liquidityPoolWithdrawOp")
    }

    func test_OperationBodyXDR_manageBuyOfferOp() throws {
        let original: OperationBodyXDR = .manageBuyOfferOp(ManageOfferOperationXDR(selling: .native, buying: .native, amount: Int64(1234567), price: PriceXDR(n: 42, d: 42), offerID: Int64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.manageBuyOfferOp")
    }

    func test_OperationBodyXDR_manageDataOp() throws {
        let original: OperationBodyXDR = .manageDataOp(ManageDataOperationXDR(dataName: "test_string", dataValue: DataValueXDR?.none))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.manageDataOp")
    }

    func test_OperationBodyXDR_manageSellOfferOp() throws {
        let original: OperationBodyXDR = .manageSellOfferOp(ManageOfferOperationXDR(selling: .native, buying: .native, amount: Int64(1234567), price: PriceXDR(n: 42, d: 42), offerID: Int64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.manageSellOfferOp")
    }

    func test_OperationBodyXDR_pathPaymentStrictReceiveOp() throws {
        let original: OperationBodyXDR = .pathPaymentStrictReceiveOp(PathPaymentOperationXDR(sendAsset: .native, sendMax: Int64(1234567), destination: .ed25519([UInt8](repeating: 0xAB, count: 32)), destinationAsset: .native, destinationAmount: Int64(1234567), path: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.pathPaymentStrictReceiveOp")
    }

    func test_OperationBodyXDR_pathPaymentStrictSendOp() throws {
        let original: OperationBodyXDR = .pathPaymentStrictSendOp(PathPaymentOperationXDR(sendAsset: .native, sendMax: Int64(1234567), destination: .ed25519([UInt8](repeating: 0xAB, count: 32)), destinationAsset: .native, destinationAmount: Int64(1234567), path: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.pathPaymentStrictSendOp")
    }

    func test_OperationBodyXDR_paymentOp() throws {
        let original: OperationBodyXDR = .paymentOp(PaymentOperationXDR(destination: .ed25519([UInt8](repeating: 0xAB, count: 32)), asset: .native, amount: Int64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.paymentOp")
    }

    func test_OperationBodyXDR_restoreFootprintOp() throws {
        let original: OperationBodyXDR = .restoreFootprintOp(RestoreFootprintOpXDR(ext: .void))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.restoreFootprintOp")
    }

    func test_OperationBodyXDR_setOptionsOp() throws {
        let original: OperationBodyXDR = .setOptionsOp(SetOptionsOperationXDR(inflationDestination: PublicKey?.none, clearFlags: UInt32?.none, setFlags: UInt32?.none, masterWeight: UInt32?.none, lowThreshold: UInt32?.none, medThreshold: UInt32?.none, highThreshold: UInt32?.none, homeDomain: String?.none, signer: SignerXDR?.none))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.setOptionsOp")
    }

    func test_OperationBodyXDR_setTrustLineFlagsOp() throws {
        let original: OperationBodyXDR = .setTrustLineFlagsOp(SetTrustLineFlagsOpXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .native, setFlags: UInt32(42), clearFlags: UInt32(42)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationBodyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationBodyXDR.setTrustLineFlagsOp")
    }

    func test_PreconditionsXDR_none() throws {
        let original: PreconditionsXDR = .none
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try PreconditionsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for PreconditionsXDR.none")
    }

    func test_PreconditionsXDR_time() throws {
        let original: PreconditionsXDR = .time(TimeBoundsXDR(minTime: UInt64(1234567), maxTime: UInt64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try PreconditionsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for PreconditionsXDR.time")
    }

    func test_PreconditionsXDR_v2() throws {
        let original: PreconditionsXDR = .v2(PreconditionsV2XDR(timeBounds: TimeBoundsXDR?.none, ledgerBounds: LedgerBoundsXDR?.none, sequenceNumber: Int64?.none, minSeqAge: UInt64(1234567), minSeqLedgerGap: UInt32(42), extraSigners: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try PreconditionsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for PreconditionsXDR.v2")
    }

    func test_RevokeSponsorshipOpXDR_revokeSponsorshipLedgerEntry() throws {
        let original: RevokeSponsorshipOpXDR = .revokeSponsorshipLedgerEntry(.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try RevokeSponsorshipOpXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for RevokeSponsorshipOpXDR.revokeSponsorshipLedgerEntry")
    }

    func test_RevokeSponsorshipOpXDR_revokeSponsorshipSignerEntry() throws {
        let original: RevokeSponsorshipOpXDR = .revokeSponsorshipSignerEntry(RevokeSponsorshipSignerXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), signerKey: .ed25519(WrappedData32(Data(repeating: 0xAB, count: 32)))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try RevokeSponsorshipOpXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for RevokeSponsorshipOpXDR.revokeSponsorshipSignerEntry")
    }

    func test_SCAddressXDR_account() throws {
        let original: SCAddressXDR = .account(try PublicKey([UInt8](repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCAddressXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCAddressXDR.account")
    }

    func test_SCAddressXDR_claimableBalanceId() throws {
        let original: SCAddressXDR = .claimableBalanceId(.claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCAddressXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCAddressXDR.claimableBalanceId")
    }

    func test_SCAddressXDR_contract() throws {
        let original: SCAddressXDR = .contract(WrappedData32(Data(repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCAddressXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCAddressXDR.contract")
    }

    func test_SCAddressXDR_liquidityPoolId() throws {
        let original: SCAddressXDR = .liquidityPoolId(WrappedData32(Data(repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCAddressXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCAddressXDR.liquidityPoolId")
    }

    func test_SCAddressXDR_muxedAccount() throws {
        let original: SCAddressXDR = .muxedAccount(MuxedAccountMed25519XDR(id: UInt64(1), sourceAccountEd25519: [UInt8](repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCAddressXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCAddressXDR.muxedAccount")
    }

    func test_SCErrorXDR_auth() throws {
        let original: SCErrorXDR = .auth(.arithDomain)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCErrorXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCErrorXDR.auth")
    }

    func test_SCErrorXDR_budget() throws {
        let original: SCErrorXDR = .budget(.arithDomain)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCErrorXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCErrorXDR.budget")
    }

    func test_SCErrorXDR_context() throws {
        let original: SCErrorXDR = .context(.arithDomain)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCErrorXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCErrorXDR.context")
    }

    func test_SCErrorXDR_contract() throws {
        let original: SCErrorXDR = .contract(UInt32(42))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCErrorXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCErrorXDR.contract")
    }

    func test_SCErrorXDR_crypto() throws {
        let original: SCErrorXDR = .crypto(.arithDomain)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCErrorXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCErrorXDR.crypto")
    }

    func test_SCErrorXDR_events() throws {
        let original: SCErrorXDR = .events(.arithDomain)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCErrorXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCErrorXDR.events")
    }

    func test_SCErrorXDR_object() throws {
        let original: SCErrorXDR = .object(.arithDomain)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCErrorXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCErrorXDR.object")
    }

    func test_SCErrorXDR_storage() throws {
        let original: SCErrorXDR = .storage(.arithDomain)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCErrorXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCErrorXDR.storage")
    }

    func test_SCErrorXDR_value() throws {
        let original: SCErrorXDR = .value(.arithDomain)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCErrorXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCErrorXDR.value")
    }

    func test_SCErrorXDR_wasmVm() throws {
        let original: SCErrorXDR = .wasmVm(.arithDomain)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCErrorXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCErrorXDR.wasmVm")
    }

    func test_SCValXDR_address() throws {
        let original: SCValXDR = .address(.account(try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.address")
    }

    func test_SCValXDR_bool() throws {
        let original: SCValXDR = .bool(true)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.bool")
    }

    func test_SCValXDR_bytes() throws {
        let original: SCValXDR = .bytes(Data([0x01, 0x02, 0x03]))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.bytes")
    }

    func test_SCValXDR_contractInstance() throws {
        let original: SCValXDR = .contractInstance(SCContractInstanceXDR(executable: .token, storage: [SCMapEntryXDR]?.none))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.contractInstance")
    }

    func test_SCValXDR_duration() throws {
        let original: SCValXDR = .duration(UInt64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.duration")
    }

    func test_SCValXDR_error() throws {
        let original: SCValXDR = .error(.contract(UInt32(42)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.error")
    }

    func test_SCValXDR_i128() throws {
        let original: SCValXDR = .i128(Int128PartsXDR(hi: Int64(1234567), lo: UInt64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.i128")
    }

    func test_SCValXDR_i256() throws {
        let original: SCValXDR = .i256(Int256PartsXDR(hiHi: Int64(1234567), hiLo: UInt64(1234567), loHi: UInt64(1234567), loLo: UInt64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.i256")
    }

    func test_SCValXDR_i32() throws {
        let original: SCValXDR = .i32(42)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.i32")
    }

    func test_SCValXDR_i64() throws {
        let original: SCValXDR = .i64(Int64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.i64")
    }

    func test_SCValXDR_ledgerKeyContractInstance() throws {
        let original: SCValXDR = .ledgerKeyContractInstance
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.ledgerKeyContractInstance")
    }

    func test_SCValXDR_ledgerKeyNonce() throws {
        let original: SCValXDR = .ledgerKeyNonce(SCNonceKeyXDR(nonce: Int64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.ledgerKeyNonce")
    }

    func test_SCValXDR_map() throws {
        let original: SCValXDR = .map([])
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.map")
    }

    func test_SCValXDR_string() throws {
        let original: SCValXDR = .string("test_string")
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.string")
    }

    func test_SCValXDR_symbol() throws {
        let original: SCValXDR = .symbol("test_string")
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.symbol")
    }

    func test_SCValXDR_timepoint() throws {
        let original: SCValXDR = .timepoint(UInt64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.timepoint")
    }

    func test_SCValXDR_u128() throws {
        let original: SCValXDR = .u128(UInt128PartsXDR(hi: UInt64(1234567), lo: UInt64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.u128")
    }

    func test_SCValXDR_u256() throws {
        let original: SCValXDR = .u256(UInt256PartsXDR(hiHi: UInt64(1234567), hiLo: UInt64(1234567), loHi: UInt64(1234567), loLo: UInt64(1234567)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.u256")
    }

    func test_SCValXDR_u32() throws {
        let original: SCValXDR = .u32(UInt32(42))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.u32")
    }

    func test_SCValXDR_u64() throws {
        let original: SCValXDR = .u64(UInt64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.u64")
    }

    func test_SCValXDR_vec() throws {
        let original: SCValXDR = .vec([])
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.vec")
    }

    func test_SCValXDR_void() throws {
        let original: SCValXDR = .void
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCValXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCValXDR.void")
    }

    func test_SignerKeyXDR_ed25519() throws {
        let original: SignerKeyXDR = .ed25519(WrappedData32(Data(repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SignerKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SignerKeyXDR.ed25519")
    }

    func test_SignerKeyXDR_hashX() throws {
        let original: SignerKeyXDR = .hashX(WrappedData32(Data(repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SignerKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SignerKeyXDR.hashX")
    }

    func test_SignerKeyXDR_preAuthTx() throws {
        let original: SignerKeyXDR = .preAuthTx(WrappedData32(Data(repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SignerKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SignerKeyXDR.preAuthTx")
    }

    func test_SignerKeyXDR_signedPayload() throws {
        let original: SignerKeyXDR = .signedPayload(Ed25519SignedPayload(ed25519: WrappedData32(Data(repeating: 0xAB, count: 32)), payload: Data([0x01, 0x02, 0x03])))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SignerKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SignerKeyXDR.signedPayload")
    }

    func test_SorobanAuthorizedFunctionXDR_contractFn() throws {
        let original: SorobanAuthorizedFunctionXDR = .contractFn(InvokeContractArgsXDR(contractAddress: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), functionName: "test_string", args: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SorobanAuthorizedFunctionXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SorobanAuthorizedFunctionXDR.contractFn")
    }

    func test_SorobanAuthorizedFunctionXDR_createContractHostFn() throws {
        let original: SorobanAuthorizedFunctionXDR = .createContractHostFn(CreateContractArgsXDR(contractIDPreimage: .fromAsset(.native), executable: .token))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SorobanAuthorizedFunctionXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SorobanAuthorizedFunctionXDR.createContractHostFn")
    }

    func test_SorobanAuthorizedFunctionXDR_createContractV2HostFn() throws {
        let original: SorobanAuthorizedFunctionXDR = .createContractV2HostFn(CreateContractV2ArgsXDR(contractIDPreimage: .fromAsset(.native), executable: .token, constructorArgs: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SorobanAuthorizedFunctionXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SorobanAuthorizedFunctionXDR.createContractV2HostFn")
    }

    func test_SorobanCredentialsXDR_address() throws {
        let original: SorobanCredentialsXDR = .address(SorobanAddressCredentialsXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), nonce: Int64(1234567), signatureExpirationLedger: UInt32(42), signature: .void))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SorobanCredentialsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SorobanCredentialsXDR.address")
    }

    func test_SorobanCredentialsXDR_sourceAccount() throws {
        let original: SorobanCredentialsXDR = .sourceAccount
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SorobanCredentialsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SorobanCredentialsXDR.sourceAccount")
    }

    func test_SorobanResourcesExt_resourceExt() throws {
        let original: SorobanResourcesExt = .resourceExt(SorobanResourcesExtV0(archivedSorobanEntries: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SorobanResourcesExt.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SorobanResourcesExt.resourceExt")
    }

    func test_SorobanResourcesExt_void() throws {
        let original: SorobanResourcesExt = .void
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SorobanResourcesExt.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SorobanResourcesExt.void")
    }

    func test_TransactionEnvelopeXDR_feeBump() throws {
        let original: TransactionEnvelopeXDR = .feeBump(FeeBumpTransactionEnvelopeXDR(tx: FeeBumpTransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), innerTx: .v1(TransactionV1EnvelopeXDR(tx: TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, memo: .none, operations: [], maxOperationFee: UInt32(100)), signatures: [])), fee: UInt64(2000)), signatures: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try TransactionEnvelopeXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for TransactionEnvelopeXDR.feeBump")
    }

    func test_TransactionEnvelopeXDR_v0() throws {
        let original: TransactionEnvelopeXDR = .v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try! PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try TransactionEnvelopeXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for TransactionEnvelopeXDR.v0")
    }

    func test_TransactionEnvelopeXDR_v1() throws {
        let original: TransactionEnvelopeXDR = .v1(TransactionV1EnvelopeXDR(tx: TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, memo: .none, operations: [], maxOperationFee: UInt32(100)), signatures: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try TransactionEnvelopeXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for TransactionEnvelopeXDR.v1")
    }

    func test_TransactionV0XDRExtXDR_void() throws {
        let original: TransactionV0XDRExtXDR = .void
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try TransactionV0XDRExtXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for TransactionV0XDRExtXDR.void")
    }

    func test_TrustlineAssetXDR_alphanum12() throws {
        let original: TrustlineAssetXDR = .alphanum12(Alpha12XDR(assetCode: WrappedData12(Data([0x55, 0x53, 0x44, 0x43, 0x54, 0x4f, 0x4b, 0x45, 0x4e, 0x00, 0x00, 0x00])), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try TrustlineAssetXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for TrustlineAssetXDR.alphanum12")
    }

    func test_TrustlineAssetXDR_alphanum4() throws {
        let original: TrustlineAssetXDR = .alphanum4(Alpha4XDR(assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try TrustlineAssetXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for TrustlineAssetXDR.alphanum4")
    }

    func test_TrustlineAssetXDR_native() throws {
        let original: TrustlineAssetXDR = .native
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try TrustlineAssetXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for TrustlineAssetXDR.native")
    }

    func test_TrustlineAssetXDR_poolShare() throws {
        let original: TrustlineAssetXDR = .poolShare(WrappedData32(Data(repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try TrustlineAssetXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for TrustlineAssetXDR.poolShare")
    }

}
