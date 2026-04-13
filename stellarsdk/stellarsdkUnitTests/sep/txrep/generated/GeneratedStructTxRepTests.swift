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

final class GeneratedStructTxRepTests: XCTestCase {

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

    func test_AllowTrustOperationXDR_roundtrip() throws {
        let original: AllowTrustOperationXDR = AllowTrustOperationXDR(trustor: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .alphanum4(WrappedData4(Data([0x55, 0x53, 0x44, 0x00]))), authorize: UInt32(42))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try AllowTrustOperationXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for AllowTrustOperationXDR")
    }

    func test_Alpha12XDR_roundtrip() throws {
        let original: Alpha12XDR = Alpha12XDR(assetCode: WrappedData12(Data([0x55, 0x53, 0x44, 0x43, 0x54, 0x4f, 0x4b, 0x45, 0x4e, 0x00, 0x00, 0x00])), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try Alpha12XDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for Alpha12XDR")
    }

    func test_Alpha4XDR_roundtrip() throws {
        let original: Alpha4XDR = Alpha4XDR(assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try Alpha4XDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for Alpha4XDR")
    }

    func test_BeginSponsoringFutureReservesOpXDR_roundtrip() throws {
        let original: BeginSponsoringFutureReservesOpXDR = BeginSponsoringFutureReservesOpXDR(sponsoredId: try PublicKey([UInt8](repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try BeginSponsoringFutureReservesOpXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for BeginSponsoringFutureReservesOpXDR")
    }

    func test_BumpSequenceOperationXDR_roundtrip() throws {
        let original: BumpSequenceOperationXDR = BumpSequenceOperationXDR(bumpTo: Int64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try BumpSequenceOperationXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for BumpSequenceOperationXDR")
    }

    func test_ChangeTrustOperationXDR_roundtrip() throws {
        let original: ChangeTrustOperationXDR = ChangeTrustOperationXDR(asset: .native, limit: Int64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ChangeTrustOperationXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ChangeTrustOperationXDR")
    }

    func test_ClaimClaimableBalanceOpXDR_roundtrip() throws {
        let original: ClaimClaimableBalanceOpXDR = ClaimClaimableBalanceOpXDR(balanceID: .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ClaimClaimableBalanceOpXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ClaimClaimableBalanceOpXDR")
    }

    func test_ClaimantV0XDR_roundtrip() throws {
        let original: ClaimantV0XDR = ClaimantV0XDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), predicate: .claimPredicateUnconditional)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ClaimantV0XDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ClaimantV0XDR")
    }

    func test_ClawbackClaimableBalanceOpXDR_roundtrip() throws {
        let original: ClawbackClaimableBalanceOpXDR = ClawbackClaimableBalanceOpXDR(claimableBalanceID: .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ClawbackClaimableBalanceOpXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ClawbackClaimableBalanceOpXDR")
    }

    func test_ClawbackOpXDR_roundtrip() throws {
        let original: ClawbackOpXDR = ClawbackOpXDR(asset: .native, from: .ed25519([UInt8](repeating: 0xAB, count: 32)), amount: Int64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ClawbackOpXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ClawbackOpXDR")
    }

    func test_ContractIDPreimageFromAddressXDR_roundtrip() throws {
        let original: ContractIDPreimageFromAddressXDR = ContractIDPreimageFromAddressXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), salt: WrappedData32(Data(repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ContractIDPreimageFromAddressXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ContractIDPreimageFromAddressXDR")
    }

    func test_CreateAccountOperationXDR_roundtrip() throws {
        let original: CreateAccountOperationXDR = CreateAccountOperationXDR(destination: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try CreateAccountOperationXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for CreateAccountOperationXDR")
    }

    func test_CreateClaimableBalanceOpXDR_roundtrip() throws {
        let original: CreateClaimableBalanceOpXDR = CreateClaimableBalanceOpXDR(asset: .native, amount: Int64(1234567), claimants: [])
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try CreateClaimableBalanceOpXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for CreateClaimableBalanceOpXDR")
    }

    func test_CreateContractArgsXDR_roundtrip() throws {
        let original: CreateContractArgsXDR = CreateContractArgsXDR(contractIDPreimage: .fromAddress(ContractIDPreimageFromAddressXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), salt: WrappedData32(Data(repeating: 0xAB, count: 32)))), executable: .token)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try CreateContractArgsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for CreateContractArgsXDR")
    }

    func test_CreateContractV2ArgsXDR_roundtrip() throws {
        let original: CreateContractV2ArgsXDR = CreateContractV2ArgsXDR(contractIDPreimage: .fromAddress(ContractIDPreimageFromAddressXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), salt: WrappedData32(Data(repeating: 0xAB, count: 32)))), executable: .token, constructorArgs: [])
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try CreateContractV2ArgsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for CreateContractV2ArgsXDR")
    }

    func test_CreatePassiveOfferOperationXDR_roundtrip() throws {
        let original: CreatePassiveOfferOperationXDR = CreatePassiveOfferOperationXDR(selling: .native, buying: .native, amount: Int64(1234567), price: PriceXDR(n: 42, d: 42))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try CreatePassiveOfferOperationXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for CreatePassiveOfferOperationXDR")
    }

    func test_DecoratedSignatureXDR_roundtrip() throws {
        let original: DecoratedSignatureXDR = DecoratedSignatureXDR(hint: WrappedData4(Data(repeating: 0xAB, count: 4)), signature: Data([0x01, 0x02, 0x03]))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try DecoratedSignatureXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for DecoratedSignatureXDR")
    }

    func test_Ed25519SignedPayload_roundtrip() throws {
        let original: Ed25519SignedPayload = Ed25519SignedPayload(ed25519: WrappedData32(Data(repeating: 0xAB, count: 32)), payload: Data([0x01, 0x02, 0x03]))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try Ed25519SignedPayload.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for Ed25519SignedPayload")
    }

    func test_ExtendFootprintTTLOpXDR_roundtrip() throws {
        let original: ExtendFootprintTTLOpXDR = ExtendFootprintTTLOpXDR(ext: .void, extendTo: UInt32(42))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ExtendFootprintTTLOpXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ExtendFootprintTTLOpXDR")
    }

    func test_Int128PartsXDR_roundtrip() throws {
        let original: Int128PartsXDR = Int128PartsXDR(hi: Int64(1234567), lo: UInt64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try Int128PartsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for Int128PartsXDR")
    }

    func test_Int256PartsXDR_roundtrip() throws {
        let original: Int256PartsXDR = Int256PartsXDR(hiHi: Int64(1234567), hiLo: UInt64(1234567), loHi: UInt64(1234567), loLo: UInt64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try Int256PartsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for Int256PartsXDR")
    }

    func test_InvokeContractArgsXDR_roundtrip() throws {
        let original: InvokeContractArgsXDR = InvokeContractArgsXDR(contractAddress: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), functionName: "test_string", args: [])
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try InvokeContractArgsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for InvokeContractArgsXDR")
    }

    func test_InvokeHostFunctionOpXDR_roundtrip() throws {
        let original: InvokeHostFunctionOpXDR = InvokeHostFunctionOpXDR(hostFunction: .invokeContract(InvokeContractArgsXDR(contractAddress: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), functionName: "test_string", args: [])), auth: [])
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try InvokeHostFunctionOpXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for InvokeHostFunctionOpXDR")
    }

    func test_LedgerBoundsXDR_roundtrip() throws {
        let original: LedgerBoundsXDR = LedgerBoundsXDR(minLedger: UInt32(42), maxLedger: UInt32(42))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerBoundsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerBoundsXDR")
    }

    func test_LedgerFootprintXDR_roundtrip() throws {
        let original: LedgerFootprintXDR = LedgerFootprintXDR(readOnly: [], readWrite: [])
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerFootprintXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerFootprintXDR")
    }

    func test_LedgerKeyAccountXDR_roundtrip() throws {
        let original: LedgerKeyAccountXDR = LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyAccountXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyAccountXDR")
    }

    func test_LedgerKeyClaimableBalanceXDR_roundtrip() throws {
        let original: LedgerKeyClaimableBalanceXDR = LedgerKeyClaimableBalanceXDR(balanceID: .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyClaimableBalanceXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyClaimableBalanceXDR")
    }

    func test_LedgerKeyConfigSettingXDR_roundtrip() throws {
        let original: LedgerKeyConfigSettingXDR = LedgerKeyConfigSettingXDR(configSettingID: 42)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyConfigSettingXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyConfigSettingXDR")
    }

    func test_LedgerKeyContractCodeXDR_roundtrip() throws {
        let original: LedgerKeyContractCodeXDR = LedgerKeyContractCodeXDR(hash: WrappedData32(Data(repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyContractCodeXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyContractCodeXDR")
    }

    func test_LedgerKeyContractDataXDR_roundtrip() throws {
        let original: LedgerKeyContractDataXDR = LedgerKeyContractDataXDR(contract: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), key: .void, durability: .temporary)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyContractDataXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyContractDataXDR")
    }

    func test_LedgerKeyDataXDR_roundtrip() throws {
        let original: LedgerKeyDataXDR = LedgerKeyDataXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string")
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyDataXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyDataXDR")
    }

    func test_LedgerKeyLiquidityPoolXDR_roundtrip() throws {
        let original: LedgerKeyLiquidityPoolXDR = LedgerKeyLiquidityPoolXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyLiquidityPoolXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyLiquidityPoolXDR")
    }

    func test_LedgerKeyOfferXDR_roundtrip() throws {
        let original: LedgerKeyOfferXDR = LedgerKeyOfferXDR(sellerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), offerID: Int64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyOfferXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyOfferXDR")
    }

    func test_LedgerKeyTTLXDR_roundtrip() throws {
        let original: LedgerKeyTTLXDR = LedgerKeyTTLXDR(keyHash: WrappedData32(Data(repeating: 0xAB, count: 32)))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyTTLXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyTTLXDR")
    }

    func test_LedgerKeyTrustLineXDR_roundtrip() throws {
        let original: LedgerKeyTrustLineXDR = LedgerKeyTrustLineXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .native)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LedgerKeyTrustLineXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LedgerKeyTrustLineXDR")
    }

    func test_LiquidityPoolConstantProductParametersXDR_roundtrip() throws {
        let original: LiquidityPoolConstantProductParametersXDR = LiquidityPoolConstantProductParametersXDR(assetA: .native, assetB: .native, fee: 42)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LiquidityPoolConstantProductParametersXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LiquidityPoolConstantProductParametersXDR")
    }

    func test_LiquidityPoolDepositOpXDR_roundtrip() throws {
        let original: LiquidityPoolDepositOpXDR = LiquidityPoolDepositOpXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)), maxAmountA: Int64(1234567), maxAmountB: Int64(1234567), minPrice: PriceXDR(n: 42, d: 42), maxPrice: PriceXDR(n: 42, d: 42))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LiquidityPoolDepositOpXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LiquidityPoolDepositOpXDR")
    }

    func test_LiquidityPoolWithdrawOpXDR_roundtrip() throws {
        let original: LiquidityPoolWithdrawOpXDR = LiquidityPoolWithdrawOpXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)), amount: Int64(1234567), minAmountA: Int64(1234567), minAmountB: Int64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try LiquidityPoolWithdrawOpXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for LiquidityPoolWithdrawOpXDR")
    }

    func test_ManageDataOperationXDR_roundtrip() throws {
        let original: ManageDataOperationXDR = ManageDataOperationXDR(dataName: "test_string", dataValue: DataValueXDR?.none)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ManageDataOperationXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ManageDataOperationXDR")
    }

    func test_ManageOfferOperationXDR_roundtrip() throws {
        let original: ManageOfferOperationXDR = ManageOfferOperationXDR(selling: .native, buying: .native, amount: Int64(1234567), price: PriceXDR(n: 42, d: 42), offerID: Int64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try ManageOfferOperationXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for ManageOfferOperationXDR")
    }

    func test_OperationXDR_roundtrip() throws {
        let original: OperationXDR = OperationXDR(sourceAccount: MuxedAccountXDR?.none, body: .inflation)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try OperationXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for OperationXDR")
    }

    func test_PathPaymentOperationXDR_roundtrip() throws {
        let original: PathPaymentOperationXDR = PathPaymentOperationXDR(sendAsset: .native, sendMax: Int64(1234567), destination: .ed25519([UInt8](repeating: 0xAB, count: 32)), destinationAsset: .native, destinationAmount: Int64(1234567), path: [])
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try PathPaymentOperationXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for PathPaymentOperationXDR")
    }

    func test_PaymentOperationXDR_roundtrip() throws {
        let original: PaymentOperationXDR = PaymentOperationXDR(destination: .ed25519([UInt8](repeating: 0xAB, count: 32)), asset: .native, amount: Int64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try PaymentOperationXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for PaymentOperationXDR")
    }

    func test_PreconditionsV2XDR_roundtrip() throws {
        let original: PreconditionsV2XDR = PreconditionsV2XDR(timeBounds: TimeBoundsXDR?.none, ledgerBounds: LedgerBoundsXDR?.none, sequenceNumber: Int64?.none, minSeqAge: UInt64(1234567), minSeqLedgerGap: UInt32(42), extraSigners: [])
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try PreconditionsV2XDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for PreconditionsV2XDR")
    }

    func test_PriceXDR_roundtrip() throws {
        let original: PriceXDR = PriceXDR(n: 42, d: 42)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try PriceXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for PriceXDR")
    }

    func test_RestoreFootprintOpXDR_roundtrip() throws {
        let original: RestoreFootprintOpXDR = RestoreFootprintOpXDR(ext: .void)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try RestoreFootprintOpXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for RestoreFootprintOpXDR")
    }

    func test_RevokeSponsorshipSignerXDR_roundtrip() throws {
        let original: RevokeSponsorshipSignerXDR = RevokeSponsorshipSignerXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), signerKey: .ed25519(WrappedData32(Data(repeating: 0xAB, count: 32))))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try RevokeSponsorshipSignerXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for RevokeSponsorshipSignerXDR")
    }

    func test_SCContractInstanceXDR_roundtrip() throws {
        let original: SCContractInstanceXDR = SCContractInstanceXDR(executable: .token, storage: [SCMapEntryXDR]?.none)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCContractInstanceXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCContractInstanceXDR")
    }

    func test_SCMapEntryXDR_roundtrip() throws {
        let original: SCMapEntryXDR = SCMapEntryXDR(key: .void, val: .void)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCMapEntryXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCMapEntryXDR")
    }

    func test_SCNonceKeyXDR_roundtrip() throws {
        let original: SCNonceKeyXDR = SCNonceKeyXDR(nonce: Int64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SCNonceKeyXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SCNonceKeyXDR")
    }

    func test_SetOptionsOperationXDR_roundtrip() throws {
        let original: SetOptionsOperationXDR = SetOptionsOperationXDR(inflationDestination: PublicKey?.none, clearFlags: UInt32?.none, setFlags: UInt32?.none, masterWeight: UInt32?.none, lowThreshold: UInt32?.none, medThreshold: UInt32?.none, highThreshold: UInt32?.none, homeDomain: String?.none, signer: SignerXDR?.none)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SetOptionsOperationXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SetOptionsOperationXDR")
    }

    func test_SetTrustLineFlagsOpXDR_roundtrip() throws {
        let original: SetTrustLineFlagsOpXDR = SetTrustLineFlagsOpXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .native, setFlags: UInt32(42), clearFlags: UInt32(42))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SetTrustLineFlagsOpXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SetTrustLineFlagsOpXDR")
    }

    func test_SignerXDR_roundtrip() throws {
        let original: SignerXDR = SignerXDR(key: .ed25519(WrappedData32(Data(repeating: 0xAB, count: 32))), weight: UInt32(42))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SignerXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SignerXDR")
    }

    func test_SorobanAddressCredentialsXDR_roundtrip() throws {
        let original: SorobanAddressCredentialsXDR = SorobanAddressCredentialsXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), nonce: Int64(1234567), signatureExpirationLedger: UInt32(42), signature: .void)
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SorobanAddressCredentialsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SorobanAddressCredentialsXDR")
    }

    func test_SorobanAuthorizationEntryXDR_roundtrip() throws {
        let original: SorobanAuthorizationEntryXDR = SorobanAuthorizationEntryXDR(credentials: .sourceAccount, rootInvocation: SorobanAuthorizedInvocationXDR(function: .contractFn(InvokeContractArgsXDR(contractAddress: .contract(WrappedData32(Data(repeating: 0xAB, count: 32))), functionName: "fn", args: [])), subInvocations: []))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SorobanAuthorizationEntryXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SorobanAuthorizationEntryXDR")
    }

    func test_SorobanAuthorizedInvocationXDR_roundtrip() throws {
        let original: SorobanAuthorizedInvocationXDR = SorobanAuthorizedInvocationXDR(function: .contractFn(InvokeContractArgsXDR(contractAddress: .contract(WrappedData32(Data(repeating: 0xAB, count: 32))), functionName: "fn", args: [])), subInvocations: [])
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SorobanAuthorizedInvocationXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SorobanAuthorizedInvocationXDR")
    }

    func test_SorobanResourcesExtV0_roundtrip() throws {
        let original: SorobanResourcesExtV0 = SorobanResourcesExtV0(archivedSorobanEntries: [])
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SorobanResourcesExtV0.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SorobanResourcesExtV0")
    }

    func test_SorobanResourcesXDR_roundtrip() throws {
        let original: SorobanResourcesXDR = SorobanResourcesXDR(footprint: LedgerFootprintXDR(readOnly: [], readWrite: []), instructions: UInt32(42), diskReadBytes: UInt32(42), writeBytes: UInt32(42))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SorobanResourcesXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SorobanResourcesXDR")
    }

    func test_SorobanTransactionDataXDR_roundtrip() throws {
        let original: SorobanTransactionDataXDR = SorobanTransactionDataXDR(ext: .void, resources: SorobanResourcesXDR(footprint: LedgerFootprintXDR(readOnly: [], readWrite: []), instructions: UInt32(42), diskReadBytes: UInt32(42), writeBytes: UInt32(42)), resourceFee: Int64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try SorobanTransactionDataXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for SorobanTransactionDataXDR")
    }

    func test_TimeBoundsXDR_roundtrip() throws {
        let original: TimeBoundsXDR = TimeBoundsXDR(minTime: UInt64(1234567), maxTime: UInt64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try TimeBoundsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for TimeBoundsXDR")
    }

    func test_UInt128PartsXDR_roundtrip() throws {
        let original: UInt128PartsXDR = UInt128PartsXDR(hi: UInt64(1234567), lo: UInt64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try UInt128PartsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for UInt128PartsXDR")
    }

    func test_UInt256PartsXDR_roundtrip() throws {
        let original: UInt256PartsXDR = UInt256PartsXDR(hiHi: UInt64(1234567), hiLo: UInt64(1234567), loHi: UInt64(1234567), loLo: UInt64(1234567))
        var lines: [String] = []
        try original.toTxRep(prefix: "k", lines: &lines)
        let map = Self.parseTxRepLines(lines)
        let back = try UInt256PartsXDR.fromTxRep(map, prefix: "k")
        let originalB64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        let backB64 = try Data(XDREncoder.encode(back)).base64EncodedString()
        XCTAssertEqual(backB64, originalB64, "TxRep roundtrip mismatch for UInt256PartsXDR")
    }

}
