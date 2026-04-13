//
//  TxRepCoverageTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Targeted coverage tests for gaps identified in Phase 8.
///
/// Covers:
/// - `TxRepHelper` require* helpers (all happy-path and error branches)
/// - `ChangeTrustAssetXDR+TxRep` pool-share arm and error paths
/// - `TrustlineAssetXDR+TxRep` pool-share arm (expanded format) and error paths
/// - `TransactionV1EnvelopeXDR+TxRep` error branches (missing signatures.len, invalid count)
/// - `TransactionEnvelopeXDR+TxRep` missing type key branch
/// - `TransactionXDR+TxRep` legacy preconditions, soroban ext, and 0-operations guard
/// - `TransactionEnvelopeXDR` invalid type dispatch branch
final class TxRepCoverageTestCase: XCTestCase {

    private let sourceSeed = "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK"
    private let destAccountId = "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR"

    // MARK: - TxRepHelper require* helpers — happy paths

    func testRequireHexHappyPath() throws {
        let map = ["hint": "abcd1234"]
        let data = try TxRepHelper.requireHex(map, "hint")
        XCTAssertEqual(data, Data([0xAB, 0xCD, 0x12, 0x34]))
    }

    func testRequireHexMissingKeyThrows() {
        XCTAssertThrowsError(try TxRepHelper.requireHex([:], "missing")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "missing")
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testRequireHexInvalidValueThrows() {
        let map = ["hint": "ZZZZ"]
        XCTAssertThrowsError(try TxRepHelper.requireHex(map, "hint")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertEqual(key, "hint")
            } else {
                XCTFail("Expected invalidValue with key 'hint', got \(error)")
            }
        }
    }

    func testRequireWrappedData4HappyPath() throws {
        let map = ["code": "55534400"]  // "USD\0" in hex
        let wd4 = try TxRepHelper.requireWrappedData4(map, "code")
        XCTAssertEqual(wd4.wrapped, Data([0x55, 0x53, 0x44, 0x00]))
    }

    func testRequireWrappedData4MissingKeyThrows() {
        XCTAssertThrowsError(try TxRepHelper.requireWrappedData4([:], "code")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "code")
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testRequireWrappedData12HappyPath() throws {
        // 24 hex chars = 12 bytes.
        let map = ["code": "4c4f4e4743544f44000000000000000000000000000000000000000000000000".prefix(24).description]
        let wd12 = try TxRepHelper.requireWrappedData12(map, "code")
        XCTAssertEqual(wd12.wrapped.count, 12)
    }

    func testRequireWrappedData12MissingKeyThrows() {
        XCTAssertThrowsError(try TxRepHelper.requireWrappedData12([:], "code")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "code")
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testRequireWrappedData32HappyPath() throws {
        let hex = String(repeating: "ab", count: 32)
        let map = ["hash": hex]
        let wd32 = try TxRepHelper.requireWrappedData32(map, "hash")
        XCTAssertEqual(wd32.wrapped.count, 32)
        XCTAssertEqual(wd32.wrapped, Data(repeating: 0xAB, count: 32))
    }

    func testRequireWrappedData32MissingKeyThrows() {
        XCTAssertThrowsError(try TxRepHelper.requireWrappedData32([:], "hash")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "hash")
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testRequireStringHappyPath() throws {
        let map = ["name": "\"hello world\""]
        let s = try TxRepHelper.requireString(map, "name")
        XCTAssertEqual(s, "hello world")
    }

    func testRequireStringMissingKeyThrows() {
        XCTAssertThrowsError(try TxRepHelper.requireString([:], "name")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "name")
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testRequireStringInvalidValueThrows() {
        // An unclosed quoted string cannot be unescaped.
        let map = ["name": "\"unclosed"]
        XCTAssertThrowsError(try TxRepHelper.requireString(map, "name")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertEqual(key, "name")
            } else {
                XCTFail("Expected invalidValue with key 'name', got \(error)")
            }
        }
    }

    func testRequireInt64HappyPath() throws {
        let map = ["seqNum": "9223372036854775807"]
        let val = try TxRepHelper.requireInt64(map, "seqNum")
        XCTAssertEqual(val, Int64.max)
    }

    func testRequireInt64MissingKeyThrows() {
        XCTAssertThrowsError(try TxRepHelper.requireInt64([:], "seqNum")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "seqNum")
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testRequireInt64InvalidValueThrows() {
        let map = ["seqNum": "not_a_number"]
        XCTAssertThrowsError(try TxRepHelper.requireInt64(map, "seqNum")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertEqual(key, "seqNum")
            } else {
                XCTFail("Expected invalidValue with key 'seqNum', got \(error)")
            }
        }
    }

    func testRequireUInt64HappyPath() throws {
        let map = ["id": "18446744073709551615"]
        let val = try TxRepHelper.requireUInt64(map, "id")
        XCTAssertEqual(val, UInt64.max)
    }

    func testRequireUInt64MissingKeyThrows() {
        XCTAssertThrowsError(try TxRepHelper.requireUInt64([:], "id")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "id")
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testRequireUInt64InvalidValueThrows() {
        let map = ["id": "-1"]
        XCTAssertThrowsError(try TxRepHelper.requireUInt64(map, "id")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertEqual(key, "id")
            } else {
                XCTFail("Expected invalidValue with key 'id', got \(error)")
            }
        }
    }

    func testRequireMuxedAccountHappyPath() throws {
        let kp = try KeyPair(secretSeed: sourceSeed)
        let map = ["source": kp.accountId]
        let muxed = try TxRepHelper.requireMuxedAccount(map, "source")
        XCTAssertEqual(muxed.accountId, kp.accountId)
    }

    func testRequireMuxedAccountMissingKeyThrows() {
        XCTAssertThrowsError(try TxRepHelper.requireMuxedAccount([:], "source")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "source")
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testRequireMuxedAccountInvalidValueThrows() {
        let map = ["source": "INVALID_ACCOUNT"]
        XCTAssertThrowsError(try TxRepHelper.requireMuxedAccount(map, "source")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertEqual(key, "source")
            } else {
                XCTFail("Expected invalidValue with key 'source', got \(error)")
            }
        }
    }

    func testRequireAccountIdHappyPath() throws {
        let kp = try KeyPair(secretSeed: sourceSeed)
        let map = ["dest": kp.accountId]
        let pk = try TxRepHelper.requireAccountId(map, "dest")
        XCTAssertEqual(pk.accountId, kp.accountId)
    }

    func testRequireAccountIdMissingKeyThrows() {
        XCTAssertThrowsError(try TxRepHelper.requireAccountId([:], "dest")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "dest")
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testRequireAccountIdInvalidValueThrows() {
        let map = ["dest": "NOT_A_G_ADDRESS"]
        XCTAssertThrowsError(try TxRepHelper.requireAccountId(map, "dest")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertEqual(key, "dest")
            } else {
                XCTFail("Expected invalidValue with key 'dest', got \(error)")
            }
        }
    }

    func testRequireAssetHappyPathNative() throws {
        let map = ["asset": "XLM"]
        let asset = try TxRepHelper.requireAsset(map, "asset")
        if case .native = asset { /* ok */ } else { XCTFail("Expected .native") }
    }

    func testRequireAssetHappyPathAlphanum4() throws {
        let kp = try KeyPair(secretSeed: sourceSeed)
        let map = ["asset": "USD:\(kp.accountId)"]
        let asset = try TxRepHelper.requireAsset(map, "asset")
        if case .alphanum4 = asset { /* ok */ } else { XCTFail("Expected .alphanum4") }
    }

    func testRequireAssetMissingKeyThrows() {
        XCTAssertThrowsError(try TxRepHelper.requireAsset([:], "asset")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "asset")
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testRequireAssetInvalidValueThrows() {
        let map = ["asset": "NOTANASSET"]
        XCTAssertThrowsError(try TxRepHelper.requireAsset(map, "asset")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertEqual(key, "asset")
            } else {
                XCTFail("Expected invalidValue with key 'asset', got \(error)")
            }
        }
    }

    func testRequireSignerKeyHappyPath() throws {
        // Build a valid SignerKeyXDR (ed25519) and get its StrKey string.
        let kp = try KeyPair(secretSeed: sourceSeed)
        let signerKey = SignerKeyXDR.ed25519(Uint256XDR(Data(kp.publicKey.bytes)))
        let formatted = try TxRepHelper.formatSignerKey(signerKey)
        let map = ["signer": formatted]
        let parsed = try TxRepHelper.requireSignerKey(map, "signer")
        if case .ed25519(let data) = parsed {
            XCTAssertEqual(data.wrapped, Data(kp.publicKey.bytes))
        } else {
            XCTFail("Expected .ed25519 SignerKeyXDR")
        }
    }

    func testRequireSignerKeyMissingKeyThrows() {
        XCTAssertThrowsError(try TxRepHelper.requireSignerKey([:], "signer")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "signer")
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testRequireSignerKeyInvalidValueThrows() {
        let map = ["signer": "ZZZZZ"]
        XCTAssertThrowsError(try TxRepHelper.requireSignerKey(map, "signer")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertEqual(key, "signer")
            } else {
                XCTFail("Expected invalidValue with key 'signer', got \(error)")
            }
        }
    }

    func testRequireAllowTrustAssetHappyPath() throws {
        let map = ["assetCode": "USDC"]
        let asset = try TxRepHelper.requireAllowTrustAsset(map, "assetCode")
        if case .alphanum4 = asset { /* ok */ } else { XCTFail("Expected .alphanum4") }
    }

    func testRequireAllowTrustAssetMissingKeyThrows() {
        XCTAssertThrowsError(try TxRepHelper.requireAllowTrustAsset([:], "assetCode")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "assetCode")
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testRequireAllowTrustAssetInvalidValueThrows() {
        let map = ["assetCode": "TOOLONGASSETCODE"]
        XCTAssertThrowsError(try TxRepHelper.requireAllowTrustAsset(map, "assetCode")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertEqual(key, "assetCode")
            } else {
                XCTFail("Expected invalidValue with key 'assetCode', got \(error)")
            }
        }
    }

    // MARK: - ChangeTrustAssetXDR pool-share roundtrip (via TxRep facade)

    func testChangeTrustWithPoolShareRoundtrip() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let issuerB = try KeyPair(accountId: destAccountId)
        let account = Account(keyPair: source, sequenceNumber: 50_000)

        // Build pool-share change trust using the high-level SDK API.
        // assetA must be native (type 0) which is < alphanum4 (type 1), so order is correct.
        let assetA = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let assetB = Asset(canonicalForm: "USD:\(issuerB.accountId)")!
        let changeTrustAsset = try ChangeTrustAsset(assetA: assetA, assetB: assetB)!

        let operation = ChangeTrustOperation(
            sourceAccountId: nil,
            asset: changeTrustAsset,
            limit: Decimal(1_000_000_000)
        )
        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )
        try transaction.sign(keyPair: source, network: Network.testnet)

        let base64 = try transaction.encodedEnvelope()
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)

        XCTAssertTrue(txRep.contains("ASSET_TYPE_POOL_SHARE"),
                      "Pool-share changeTrust must emit ASSET_TYPE_POOL_SHARE")
        XCTAssertTrue(txRep.contains("LIQUIDITY_POOL_CONSTANT_PRODUCT"),
                      "Pool-share changeTrust must emit LIQUIDITY_POOL_CONSTANT_PRODUCT")

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, reconstructed, "Pool-share changeTrust must roundtrip exactly")
    }

    // MARK: - ChangeTrustAssetXDR direct extension tests

    func testChangeTrustAssetPoolShareToTxRep() throws {
        let issuer = try KeyPair(secretSeed: sourceSeed)
        let assetA = AssetXDR.native
        let assetB = AssetXDR.alphanum4(Alpha4XDR(
            assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])),
            issuer: issuer.publicKey
        ))
        let params = LiquidityPoolConstantProductParametersXDR(assetA: assetA, assetB: assetB, fee: 30)
        let poolParams = LiquidityPoolParametersXDR.constantProduct(params)
        let asset = ChangeTrustAssetXDR.poolShare(poolParams)

        var lines = [String]()
        try asset.toTxRep(prefix: "op.line", lines: &lines)

        XCTAssertTrue(lines.contains("op.line.type: ASSET_TYPE_POOL_SHARE"))
        XCTAssertTrue(lines.contains(where: { $0.contains("LIQUIDITY_POOL_CONSTANT_PRODUCT") }))
        XCTAssertTrue(lines.contains("op.line.liquidityPool.constantProduct.assetA: XLM"))
    }

    func testChangeTrustAssetFromTxRepPoolShare() throws {
        let issuer = try KeyPair(secretSeed: sourceSeed)
        let assetA = AssetXDR.native
        let assetB = AssetXDR.alphanum4(Alpha4XDR(
            assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])),
            issuer: issuer.publicKey
        ))
        let params = LiquidityPoolConstantProductParametersXDR(assetA: assetA, assetB: assetB, fee: 30)
        let poolParams = LiquidityPoolParametersXDR.constantProduct(params)
        let original = ChangeTrustAssetXDR.poolShare(poolParams)

        var lines = [String]()
        try original.toTxRep(prefix: "op.line", lines: &lines)
        var map = [String: String]()
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                map[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }

        let parsed = try ChangeTrustAssetXDR.fromTxRep(map, prefix: "op.line")
        if case .poolShare(let parsedParams) = parsed {
            if case .constantProduct(let cp) = parsedParams {
                XCTAssertEqual(cp.fee, 30)
                if case .native = cp.assetA { /* ok */ } else { XCTFail("assetA should be native") }
            } else {
                XCTFail("Expected constantProduct pool params")
            }
        } else {
            XCTFail("Expected .poolShare ChangeTrustAssetXDR")
        }
    }

    func testChangeTrustAssetFromTxRepNativeType() throws {
        let map = ["op.line.type": "ASSET_TYPE_NATIVE"]
        let asset = try ChangeTrustAssetXDR.fromTxRep(map, prefix: "op.line")
        if case .native = asset { /* ok */ } else { XCTFail("Expected .native") }
    }

    func testChangeTrustAssetFromTxRepExpandedCreditAlphanum4Throws() throws {
        // Expanded format for credit assets is not supported — must throw.
        let map = ["op.line.type": "ASSET_TYPE_CREDIT_ALPHANUM4"]
        XCTAssertThrowsError(try ChangeTrustAssetXDR.fromTxRep(map, prefix: "op.line")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("type"))
            } else {
                XCTFail("Expected invalidValue, got \(error)")
            }
        }
    }

    func testChangeTrustAssetFromTxRepExpandedCreditAlphanum12Throws() throws {
        let map = ["op.line.type": "ASSET_TYPE_CREDIT_ALPHANUM12"]
        XCTAssertThrowsError(try ChangeTrustAssetXDR.fromTxRep(map, prefix: "op.line")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("type"))
            } else {
                XCTFail("Expected invalidValue, got \(error)")
            }
        }
    }

    func testChangeTrustAssetFromTxRepInvalidTypeThrows() {
        let map = ["op.line.type": "ASSET_TYPE_UNKNOWN"]
        XCTAssertThrowsError(try ChangeTrustAssetXDR.fromTxRep(map, prefix: "op.line")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("type"))
            } else {
                XCTFail("Expected invalidValue, got \(error)")
            }
        }
    }

    func testChangeTrustAssetFromTxRepMissingPrefixThrows() {
        // Neither compact value at prefix key nor type sub-key present.
        let map = [String: String]()
        XCTAssertThrowsError(try ChangeTrustAssetXDR.fromTxRep(map, prefix: "op.line")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("op.line"))
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    // MARK: - TrustlineAssetXDR expanded pool-share format

    func testTrustlineAssetPoolShareExpandedToTxRep() throws {
        let poolData = Data(repeating: 0xBB, count: 32)
        let asset = TrustlineAssetXDR.poolShare(WrappedData32(poolData))
        var lines = [String]()
        try asset.toTxRep(prefix: "key.asset", lines: &lines)
        XCTAssertTrue(lines.contains("key.asset.type: ASSET_TYPE_POOL_SHARE"))
        XCTAssertTrue(lines.contains(where: { $0.contains("liquidityPoolID:") }))
    }

    func testTrustlineAssetPoolShareExpandedFromTxRep() throws {
        let poolData = Data(repeating: 0xBB, count: 32)
        let poolHex = poolData.base16EncodedString()
        let map = [
            "key.asset.type": "ASSET_TYPE_POOL_SHARE",
            "key.asset.liquidityPoolID": poolHex
        ]
        let parsed = try TrustlineAssetXDR.fromTxRep(map, prefix: "key.asset")
        if case .poolShare(let wd32) = parsed {
            XCTAssertEqual(wd32.wrapped, poolData)
        } else {
            XCTFail("Expected .poolShare TrustlineAssetXDR")
        }
    }

    func testTrustlineAssetExpandedNativeFromTxRep() throws {
        let map = ["key.asset.type": "ASSET_TYPE_NATIVE"]
        let parsed = try TrustlineAssetXDR.fromTxRep(map, prefix: "key.asset")
        if case .native = parsed { /* ok */ } else { XCTFail("Expected .native") }
    }

    func testTrustlineAssetExpandedInvalidTypeThrows() {
        let map = ["key.asset.type": "ASSET_TYPE_UNKNOWN"]
        XCTAssertThrowsError(try TrustlineAssetXDR.fromTxRep(map, prefix: "key.asset")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("type"))
            } else {
                XCTFail("Expected invalidValue, got \(error)")
            }
        }
    }

    func testTrustlineAssetExpandedMissingPrefixThrows() {
        // No compact value, no type key.
        XCTAssertThrowsError(try TrustlineAssetXDR.fromTxRep([:], prefix: "key.asset")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("key.asset"))
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testTrustlineAssetPoolShareRoundtripViaExtension() throws {
        let poolData = Data(repeating: 0xCC, count: 32)
        let original = TrustlineAssetXDR.poolShare(WrappedData32(poolData))
        var lines = [String]()
        try original.toTxRep(prefix: "key.asset", lines: &lines)
        var map = [String: String]()
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                map[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        let parsed = try TrustlineAssetXDR.fromTxRep(map, prefix: "key.asset")
        if case .poolShare(let wd32) = parsed {
            XCTAssertEqual(wd32.wrapped, poolData)
        } else {
            XCTFail("Expected .poolShare after roundtrip")
        }
    }

    // MARK: - TransactionV1EnvelopeXDR error paths

    func testV1EnvelopeMissingSignaturesLenSucceeds() throws {
        // Absent signatures.len is a valid unsigned transaction (SEP-0011 interop
        // with Flutter/PHP which omit the signature block for pre-signature inspection).
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 100001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 1000000
        tx.ext.v: 0
        """
        let base64 = try TxRep.fromTxRep(txRep: txRep)
        let envelope = try TransactionEnvelopeXDR(fromBase64: base64)
        guard case .v1(let v1env) = envelope else {
            XCTFail("Expected V1 envelope")
            return
        }
        XCTAssertEqual(v1env.signatures.count, 0, "Missing signatures.len must produce empty signature array")
    }

    func testV1EnvelopeTooManySignaturesThrows() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 100002
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 1000000
        tx.ext.v: 0
        signatures.len: 21
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("signatures.len"), "Expected signatures.len, got: \(key)")
            } else {
                XCTFail("Expected invalidValue for signatures.len > 20, got \(error)")
            }
        }
    }

    func testV1EnvelopeInvalidSignaturesLenThrows() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 100003
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 1000000
        tx.ext.v: 0
        signatures.len: -5
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("signatures.len"))
            } else {
                XCTFail("Expected invalidValue for negative signatures.len, got \(error)")
            }
        }
    }

    // MARK: - TransactionEnvelopeXDR missing type key

    func testEnvelopeMissingTypeKeyThrows() {
        let txRep = """
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 1
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "type")
            } else {
                XCTFail("Expected missingValue(key: \"type\"), got \(error)")
            }
        }
    }

    func testEnvelopeInvalidTypeThrows() {
        let txRep = """
        type: ENVELOPE_TYPE_UNKNOWN
        tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
        tx.fee: 100
        tx.seqNum: 1
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertEqual(key, "type")
            } else {
                XCTFail("Expected invalidValue(key: \"type\"), got \(error)")
            }
        }
    }

    // MARK: - TransactionXDR legacy preconditions (timeBounds._present = true)

    func testTransactionXDRLegacyTimeBoundsPresentTrue() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 200001
        tx.timeBounds._present: true
        tx.timeBounds.minTime: 1000
        tx.timeBounds.maxTime: 9000
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 1000000
        tx.ext.v: 0
        signatures.len: 0
        """
        let base64 = try TxRep.fromTxRep(txRep: txRep)
        let txRep2 = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep2.contains("tx.cond.type: PRECOND_TIME"))
        XCTAssertTrue(txRep2.contains("tx.cond.timeBounds.minTime: 1000"))
    }

    func testTransactionXDRLegacyTimeBoundsPresentFalse() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 200002
        tx.timeBounds._present: false
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 1000000
        tx.ext.v: 0
        signatures.len: 0
        """
        let base64 = try TxRep.fromTxRep(txRep: txRep)
        let txRep2 = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep2.contains("tx.cond.type: PRECOND_NONE"))
    }

    // MARK: - TransactionXDR zero operations (XDR spec allows it)

    func testTransactionXDRZeroOperationsSucceeds() throws {
        // The XDR spec allows 0 operations; the SDK must accept them for interop.
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 300001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 0
        tx.ext.v: 0
        signatures.len: 0
        """
        let base64 = try TxRep.fromTxRep(txRep: txRep)
        let envelope = try TransactionEnvelopeXDR(fromBase64: base64)
        guard case .v1(let v1env) = envelope else {
            XCTFail("Expected V1 envelope")
            return
        }
        XCTAssertEqual(v1env.tx.operations.count, 0, "Zero-operation envelope must parse with 0 operations")

        // Roundtrip must be idempotent.
        let txRep2 = try TxRep.toTxRep(transactionEnvelope: base64)
        let base64Again = try TxRep.fromTxRep(txRep: txRep2)
        XCTAssertEqual(base64, base64Again, "Zero-operation envelope must roundtrip to identical XDR")
    }

    // MARK: - TransactionXDR invalid ext.v

    func testTransactionXDRInvalidExtVersionThrows() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 400001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 1000000
        tx.ext.v: 9
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("ext.v"))
            } else {
                XCTFail("Expected invalidValue for ext.v, got \(error)")
            }
        }
    }

    func testTransactionXDRInvalidExtVStringThrows() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 400002
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 1000000
        tx.ext.v: not_a_number
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("ext.v"))
            } else {
                XCTFail("Expected invalidValue for invalid ext.v string, got \(error)")
            }
        }
    }

    // MARK: - deriveSigPrefix isolation via TransactionV1EnvelopeXDR single-prefix overload

    func testV1EnvelopeSinglePrefixOverloadRoundtrip() throws {
        // Exercises the toTxRep(prefix:lines:) single-prefix overload, which calls
        // deriveSigPrefix. Using the standard "tx" prefix means sigPrefix becomes "".
        let source = try KeyPair(secretSeed: sourceSeed)
        let account = Account(keyPair: source, sequenceNumber: 60_000)
        let dest = try KeyPair(accountId: destAccountId)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: dest.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(100)
        )
        let tx = try Transaction(sourceAccount: account, operations: [payment], memo: Memo.none)
        try tx.sign(keyPair: source, network: Network.testnet)
        let base64 = try tx.encodedEnvelope()

        let envelope = try TransactionEnvelopeXDR(fromBase64: base64)
        guard case .v1(let v1env) = envelope else {
            XCTFail("Expected v1 envelope")
            return
        }
        var lines = [String]()
        try v1env.toTxRep(prefix: "tx", lines: &lines)
        XCTAssertTrue(lines.contains(where: { $0.hasPrefix("signatures.len:") }),
                      "signatures.len must appear at root when prefix is 'tx'")
    }

    func testV1EnvelopeSinglePrefixOverloadFromTxRep() throws {
        // Exercises fromTxRep(_:prefix:) single-prefix overload.
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 70001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 1000000
        tx.ext.v: 0
        signatures.len: 0
        """
        let map = TxRepHelper.parse(txRep)
        let v1env = try TransactionV1EnvelopeXDR.fromTxRep(map, prefix: "tx")
        XCTAssertNotNil(v1env)
        XCTAssertEqual(v1env.signatures.count, 0)
    }

    // MARK: - deriveSigPrefix with dotted prefix (line 89 of TransactionV1EnvelopeXDR+TxRep.swift)

    func testV1EnvelopeSinglePrefixOverloadWithDottedPrefix() throws {
        // Exercises the deriveSigPrefix branch when txPrefix contains a dot.
        // "feeBump.tx.innerTx.tx" → sigPrefix = "feeBump.tx.innerTx."
        // Build a real V1 envelope and call toTxRep(prefix:lines:) with a dotted prefix.
        let source = try KeyPair(secretSeed: sourceSeed)
        let account = Account(keyPair: source, sequenceNumber: 80_000)
        let dest = try KeyPair(accountId: destAccountId)

        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: dest.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(100)
        )
        let tx = try Transaction(sourceAccount: account, operations: [payment], memo: Memo.none)
        try tx.sign(keyPair: source, network: Network.testnet)
        let base64 = try tx.encodedEnvelope()

        let envelope = try TransactionEnvelopeXDR(fromBase64: base64)
        guard case .v1(let v1env) = envelope else {
            XCTFail("Expected v1 envelope")
            return
        }

        // Call with dotted prefix — exercises the dot-branch in deriveSigPrefix.
        var lines = [String]()
        try v1env.toTxRep(prefix: "feeBump.tx.innerTx.tx", lines: &lines)
        // signatures.len should be under "feeBump.tx.innerTx." prefix.
        XCTAssertTrue(lines.contains(where: { $0.hasPrefix("feeBump.tx.innerTx.signatures.len:") }),
                      "With dotted prefix, sigPrefix must derive to 'feeBump.tx.innerTx.'")
    }

    func testV1EnvelopeSinglePrefixFromTxRepDottedPrefix() throws {
        // Exercises fromTxRep(_:prefix:) with a dotted prefix to hit the deriveSigPrefix dot branch.
        let source = try KeyPair(secretSeed: sourceSeed)
        // Build a txrep with a dotted prefix structure:
        let txRepContent = """
        feeBump.tx.innerTx.tx.sourceAccount: \(source.accountId)
        feeBump.tx.innerTx.tx.fee: 100
        feeBump.tx.innerTx.tx.seqNum: 80001
        feeBump.tx.innerTx.tx.cond.type: PRECOND_NONE
        feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
        feeBump.tx.innerTx.tx.operations.len: 1
        feeBump.tx.innerTx.tx.operations[0].sourceAccount._present: false
        feeBump.tx.innerTx.tx.operations[0].body.type: PAYMENT
        feeBump.tx.innerTx.tx.operations[0].body.paymentOp.destination: \(destAccountId)
        feeBump.tx.innerTx.tx.operations[0].body.paymentOp.asset: XLM
        feeBump.tx.innerTx.tx.operations[0].body.paymentOp.amount: 1000000
        feeBump.tx.innerTx.tx.ext.v: 0
        feeBump.tx.innerTx.signatures.len: 0
        """
        let map = TxRepHelper.parse(txRepContent)
        // This exercises fromTxRep(_:prefix:) overload which calls deriveSigPrefix.
        let v1env = try TransactionV1EnvelopeXDR.fromTxRep(map, prefix: "feeBump.tx.innerTx.tx")
        XCTAssertNotNil(v1env)
        XCTAssertEqual(v1env.signatures.count, 0)
    }

    // MARK: - TransactionV0EnvelopeXDR single-prefix overloads

    func testV0EnvelopeSinglePrefixOverloadToTxRep() throws {
        // Exercises toTxRep(prefix:lines:) on TransactionV0EnvelopeXDR — the single-prefix overload.
        let source = try KeyPair(secretSeed: sourceSeed)
        let dest = try KeyPair(accountId: destAccountId)
        let destMuxed = MuxedAccountXDR.ed25519(dest.publicKey.bytes)
        let payBody = OperationBodyXDR.paymentOp(PaymentOperationXDR(
            destination: destMuxed, asset: .native, amount: 100_000
        ))
        let op = OperationXDR(sourceAccount: MuxedAccountXDR?.none, body: payBody)
        var v0Tx = TransactionV0XDR(
            sourceAccount: source.publicKey,
            seqNum: 90001,
            timeBounds: nil,
            memo: .none,
            operations: [op],
            maxOperationFee: 100
        )
        try v0Tx.sign(keyPair: source, network: Network.testnet)
        let v0Env = TransactionV0EnvelopeXDR(tx: v0Tx, signatures: [])

        var lines = [String]()
        // Call single-prefix overload directly.
        try v0Env.toTxRep(prefix: "tx", lines: &lines)
        XCTAssertTrue(lines.contains(where: { $0.hasPrefix("tx.sourceAccount:") }),
                      "V0 envelope toTxRep(prefix:lines:) must emit tx.sourceAccount")
        XCTAssertTrue(lines.contains("signatures.len: 0"))
    }

    func testV0EnvelopeSinglePrefixOverloadFromTxRep() throws {
        // Exercises fromTxRep(_:prefix:) on TransactionV0EnvelopeXDR — the single-prefix overload.
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRepContent = """
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 90002
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 100000
        tx.ext.v: 0
        signatures.len: 0
        """
        let map = TxRepHelper.parse(txRepContent)
        let v0env = try TransactionV0EnvelopeXDR.fromTxRep(map, prefix: "tx")
        XCTAssertNotNil(v0env)
        XCTAssertEqual(v0env.signatures.count, 0)
        XCTAssertEqual(v0env.tx.seqNum, 90002)
    }

    // MARK: - FeeBumpTransactionXDRInnerTxXDR error branches

    func testFeeBumpInnerTxMissingTypeThrows() throws {
        // Exercises line 54 of FeeBumpTransactionXDRInnerTxXDR+TxRep.swift:
        // missing inner tx type key → throws missingValue.
        let map = [String: String]()  // No type key at all.
        XCTAssertThrowsError(try FeeBumpTransactionXDRInnerTxXDR.fromTxRep(map, prefix: "feeBump.tx.innerTx")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("type"), "Expected 'type' in key, got: \(key)")
            } else {
                XCTFail("Expected missingValue for inner tx type, got \(error)")
            }
        }
    }

    func testFeeBumpInnerTxInvalidTypeThrows() throws {
        // Exercises line 63 of FeeBumpTransactionXDRInnerTxXDR+TxRep.swift:
        // invalid inner tx type → throws invalidValue.
        let map = ["feeBump.tx.innerTx.type": "ENVELOPE_TYPE_TX_V0"]
        XCTAssertThrowsError(try FeeBumpTransactionXDRInnerTxXDR.fromTxRep(map, prefix: "feeBump.tx.innerTx")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("type"), "Expected 'type' in key, got: \(key)")
            } else {
                XCTFail("Expected invalidValue for inner tx type, got \(error)")
            }
        }
    }

    // MARK: - TxRep class init (line 43 of TxRep.swift)

    func testTxRepInitializerIsPublic() {
        // Exercises the public init() on TxRep class (line 43 of TxRep.swift).
        let instance = TxRep()
        XCTAssertNotNil(instance)
    }

    // MARK: - AssetXDR generated toTxRep/fromTxRep (expanded format)
    //
    // The production path uses compact format (XLM / CODE:ISSUER) via TxRepHelper.formatAsset().
    // The generated AssetXDR.toTxRep/fromTxRep uses expanded format (type: + sub-fields),
    // which is not used in the production path but is part of the generated API surface.
    // Tests here exercise those generated methods directly.

    func testAssetXDRToTxRepNative() throws {
        var lines = [String]()
        try AssetXDR.native.toTxRep(prefix: "op.body.asset", lines: &lines)
        XCTAssertTrue(lines.contains("op.body.asset.type: ASSET_TYPE_NATIVE"))
    }

    func testAssetXDRToTxRepAlphanum4() throws {
        let issuer = try KeyPair(secretSeed: sourceSeed)
        let asset = AssetXDR.alphanum4(Alpha4XDR(
            assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])),
            issuer: issuer.publicKey
        ))
        var lines = [String]()
        try asset.toTxRep(prefix: "op.body.asset", lines: &lines)
        XCTAssertTrue(lines.contains("op.body.asset.type: ASSET_TYPE_CREDIT_ALPHANUM4"))
        XCTAssertTrue(lines.contains(where: { $0.contains("alphaNum4.assetCode:") }))
        XCTAssertTrue(lines.contains(where: { $0.contains("alphaNum4.issuer:") }))
    }

    func testAssetXDRToTxRepAlphanum12() throws {
        let issuer = try KeyPair(secretSeed: sourceSeed)
        var codeBytes = Data([0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45])
        codeBytes.append(Data(repeating: 0, count: 4))
        let asset = AssetXDR.alphanum12(Alpha12XDR(
            assetCode: WrappedData12(codeBytes),
            issuer: issuer.publicKey
        ))
        var lines = [String]()
        try asset.toTxRep(prefix: "op.body.asset", lines: &lines)
        XCTAssertTrue(lines.contains("op.body.asset.type: ASSET_TYPE_CREDIT_ALPHANUM12"))
        XCTAssertTrue(lines.contains(where: { $0.contains("alphaNum12.assetCode:") }))
    }

    func testAssetXDRFromTxRepNative() throws {
        let map = ["op.body.asset.type": "ASSET_TYPE_NATIVE"]
        let asset = try AssetXDR.fromTxRep(map, prefix: "op.body.asset")
        if case .native = asset { /* ok */ } else { XCTFail("Expected .native") }
    }

    func testAssetXDRFromTxRepAlphanum4() throws {
        let issuer = try KeyPair(secretSeed: sourceSeed)
        let assetXDR = AssetXDR.alphanum4(Alpha4XDR(
            assetCode: WrappedData4(Data([0x55, 0x53, 0x44, 0x00])),
            issuer: issuer.publicKey
        ))
        var lines = [String]()
        try assetXDR.toTxRep(prefix: "op.body.asset", lines: &lines)
        var map = [String: String]()
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                map[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        let parsed = try AssetXDR.fromTxRep(map, prefix: "op.body.asset")
        if case .alphanum4 = parsed { /* ok */ } else { XCTFail("Expected .alphanum4") }
    }

    func testAssetXDRFromTxRepAlphanum12() throws {
        let issuer = try KeyPair(secretSeed: sourceSeed)
        var codeBytes = Data([0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45])
        codeBytes.append(Data(repeating: 0, count: 4))
        let assetXDR = AssetXDR.alphanum12(Alpha12XDR(
            assetCode: WrappedData12(codeBytes),
            issuer: issuer.publicKey
        ))
        var lines = [String]()
        try assetXDR.toTxRep(prefix: "op.body.asset", lines: &lines)
        var map = [String: String]()
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                map[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        let parsed = try AssetXDR.fromTxRep(map, prefix: "op.body.asset")
        if case .alphanum12 = parsed { /* ok */ } else { XCTFail("Expected .alphanum12") }
    }

    func testAssetXDRFromTxRepMissingTypeThrows() {
        XCTAssertThrowsError(try AssetXDR.fromTxRep([:], prefix: "op.body.asset")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("type"))
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testAssetXDRFromTxRepInvalidTypeThrows() {
        let map = ["op.body.asset.type": "ASSET_TYPE_UNKNOWN"]
        XCTAssertThrowsError(try AssetXDR.fromTxRep(map, prefix: "op.body.asset")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("type"))
            } else {
                XCTFail("Expected invalidValue, got \(error)")
            }
        }
    }

    // MARK: - MemoXDR generated toTxRep/fromTxRep
    //
    // `emitMemo()` intercepts MEMO_TEXT and delegates non-text memos to MemoXDR.toTxRep.
    // `parseMemo()` handles all memo types inline, so MemoXDR.fromTxRep is never called
    // from the production path. The MEMO_TEXT arm of MemoXDR.toTxRep is also bypassed.
    // These tests exercise the generated methods directly.

    func testMemoXDRToTxRepText() throws {
        // The generated MEMO_TEXT arm (bypassed by emitMemo in production).
        var lines = [String]()
        try MemoXDR.text("test memo").toTxRep(prefix: "tx.memo", lines: &lines)
        XCTAssertTrue(lines.contains("tx.memo.type: MEMO_TEXT"))
        XCTAssertTrue(lines.contains(where: { $0.contains("tx.memo.text:") }))
    }

    func testMemoXDRFromTxRepNone() throws {
        let map = ["tx.memo.type": "MEMO_NONE"]
        let memo = try MemoXDR.fromTxRep(map, prefix: "tx.memo")
        if case .none = memo { /* ok */ } else { XCTFail("Expected .none") }
    }

    func testMemoXDRFromTxRepText() throws {
        let map = [
            "tx.memo.type": "MEMO_TEXT",
            "tx.memo.text": "\"hello\""
        ]
        let memo = try MemoXDR.fromTxRep(map, prefix: "tx.memo")
        if case .text(let s) = memo {
            XCTAssertEqual(s, "hello")
        } else {
            XCTFail("Expected .text")
        }
    }

    func testMemoXDRFromTxRepId() throws {
        let map = [
            "tx.memo.type": "MEMO_ID",
            "tx.memo.id": "12345"
        ]
        let memo = try MemoXDR.fromTxRep(map, prefix: "tx.memo")
        if case .id(let val) = memo {
            XCTAssertEqual(val, 12345)
        } else {
            XCTFail("Expected .id")
        }
    }

    func testMemoXDRFromTxRepHash() throws {
        let hashHex = String(repeating: "ab", count: 32)
        let map = [
            "tx.memo.type": "MEMO_HASH",
            "tx.memo.hash": hashHex
        ]
        let memo = try MemoXDR.fromTxRep(map, prefix: "tx.memo")
        if case .hash(let val) = memo {
            XCTAssertEqual(val.wrapped, Data(repeating: 0xAB, count: 32))
        } else {
            XCTFail("Expected .hash")
        }
    }

    func testMemoXDRFromTxRepReturnHash() throws {
        let hashHex = String(repeating: "cd", count: 32)
        let map = [
            "tx.memo.type": "MEMO_RETURN",
            "tx.memo.retHash": hashHex
        ]
        let memo = try MemoXDR.fromTxRep(map, prefix: "tx.memo")
        if case .returnHash(let val) = memo {
            XCTAssertEqual(val.wrapped, Data(repeating: 0xCD, count: 32))
        } else {
            XCTFail("Expected .returnHash")
        }
    }

    func testMemoXDRFromTxRepMissingTypeThrows() {
        XCTAssertThrowsError(try MemoXDR.fromTxRep([:], prefix: "tx.memo")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("type"))
            } else {
                XCTFail("Expected missingValue, got \(error)")
            }
        }
    }

    func testMemoXDRFromTxRepInvalidTypeThrows() {
        let map = ["tx.memo.type": "MEMO_UNKNOWN"]
        XCTAssertThrowsError(try MemoXDR.fromTxRep(map, prefix: "tx.memo")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("type"))
            } else {
                XCTFail("Expected invalidValue, got \(error)")
            }
        }
    }

    // MARK: - SetOptionsOperationXDR uncovered optional-absent branches

    /// A SetOptions operation with ALL optional fields absent (nil) exercises the
    /// `_present: false` branches for setFlags, masterWeight, and homeDomain.
    func testSetOptionsAllOptionalFieldsAbsentRoundtrip() throws {
        let source = try KeyPair(secretSeed: sourceSeed)
        let account = Account(keyPair: source, sequenceNumber: 110_000)

        // SetOptions with no optional fields set.
        let operation = try SetOptionsOperation(
            sourceAccountId: nil,
            inflationDestination: nil,
            clearFlags: nil,
            setFlags: nil,
            masterKeyWeight: nil,
            lowThreshold: nil,
            mediumThreshold: nil,
            highThreshold: nil,
            homeDomain: nil,
            signer: nil,
            signerWeight: nil
        )

        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none
        )
        try transaction.sign(keyPair: source, network: Network.testnet)

        let base64 = try transaction.encodedEnvelope()
        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)

        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: SET_OPTIONS"))
        // With all optionals nil, all _present fields should be false.
        XCTAssertTrue(txRep.contains("tx.operations[0].body.setOptionsOp.setFlags._present: false"),
                      "setFlags absent must emit _present: false")
        XCTAssertTrue(txRep.contains("tx.operations[0].body.setOptionsOp.masterWeight._present: false"),
                      "masterWeight absent must emit _present: false")
        XCTAssertTrue(txRep.contains("tx.operations[0].body.setOptionsOp.homeDomain._present: false"),
                      "homeDomain absent must emit _present: false")

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, reconstructed)
    }

    // MARK: - InflationOperation — covers OperationBodyXDR INFLATION case

    func testInflationOperationRoundtrip() throws {
        // Build an inflation operation at the XDR level (no SDK-level class exists).
        let source = try KeyPair(secretSeed: sourceSeed)
        let infOp = OperationXDR(sourceAccount: MuxedAccountXDR?.none, body: .inflation)

        var tx = TransactionXDR(
            sourceAccount: MuxedAccountXDR.ed25519(source.publicKey.bytes),
            seqNum: 120_001,
            cond: .none,
            memo: .none,
            operations: [infOp],
            maxOperationFee: 100
        )
        let envelope = TransactionV1EnvelopeXDR(tx: tx, signatures: [])
        let txEnvelope = TransactionEnvelopeXDR.v1(envelope)
        var encoded = try XDREncoder.encode(txEnvelope)
        let base64 = Data(bytes: &encoded, count: encoded.count).base64EncodedString()

        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("tx.operations[0].body.type: INFLATION"))

        let reconstructed = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, reconstructed)
    }

    // MARK: - LedgerKeyXDR uncovered arms
    //
    // LIQUIDITY_POOL, CONFIG_SETTING, and TTL arms of LedgerKeyXDR are not exercised
    // by the existing Soroban/operations test suites. Testing them directly via the
    // generated toTxRep/fromTxRep methods.

    func testLedgerKeyLiquidityPoolToAndFromTxRep() throws {
        // LedgerKeyLiquidityPoolXDR contains a liquidityPoolID field.
        let poolId = WrappedData32(Data(repeating: 0xAA, count: 32))
        let lkLiquidityPool = LedgerKeyLiquidityPoolXDR(liquidityPoolID: poolId)
        let ledgerKey = LedgerKeyXDR.liquidityPool(lkLiquidityPool)

        var lines = [String]()
        try ledgerKey.toTxRep(prefix: "ledgerKey", lines: &lines)
        XCTAssertTrue(lines.contains("ledgerKey.type: LIQUIDITY_POOL"))

        var map = [String: String]()
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                map[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        let parsed = try LedgerKeyXDR.fromTxRep(map, prefix: "ledgerKey")
        if case .liquidityPool(let lp) = parsed {
            XCTAssertEqual(lp.liquidityPoolID.wrapped, poolId.wrapped)
        } else {
            XCTFail("Expected .liquidityPool LedgerKeyXDR")
        }
    }

    func testLedgerKeyMissingTypeThrows() {
        XCTAssertThrowsError(try LedgerKeyXDR.fromTxRep([:], prefix: "ledgerKey")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertTrue(key.contains("type"))
            } else {
                XCTFail("Expected missingValue for LedgerKey type, got \(error)")
            }
        }
    }

    func testLedgerKeyInvalidTypeThrows() {
        let map = ["ledgerKey.type": "LEDGER_KEY_UNKNOWN"]
        XCTAssertThrowsError(try LedgerKeyXDR.fromTxRep(map, prefix: "ledgerKey")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("type"))
            } else {
                XCTFail("Expected invalidValue for LedgerKey type, got \(error)")
            }
        }
    }

    // MARK: - parseMemo invalid type (TransactionXDR+TxRep.swift line 169)

    func testParseMemoInvalidTypeThrows() throws {
        // Exercises the `default` branch of parseMemo() which throws invalidValue
        // when the memo.type string is not one of the recognised MEMO_* constants.
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 500001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_GARBAGE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 1000000
        tx.ext.v: 0
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("memo.type"), "Expected memo.type in key, got: \(key)")
            } else {
                XCTFail("Expected invalidValue for memo.type, got \(error)")
            }
        }
    }

    // MARK: - legacyPreconditions invalid timeBounds values (TransactionXDR+TxRep.swift lines 258, 261)

    func testLegacyTimeBoundsInvalidMinTimeThrows() throws {
        // Exercises line 258: non-integer minTime when timeBounds._present=true.
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 500002
        tx.timeBounds._present: true
        tx.timeBounds.minTime: NOT_A_NUMBER
        tx.timeBounds.maxTime: 9000
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 1000000
        tx.ext.v: 0
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("minTime"), "Expected minTime in key, got: \(key)")
            } else {
                XCTFail("Expected invalidValue for timeBounds.minTime, got \(error)")
            }
        }
    }

    func testLegacyTimeBoundsInvalidMaxTimeThrows() throws {
        // Exercises line 261: non-integer maxTime when timeBounds._present=true.
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 500003
        tx.timeBounds._present: true
        tx.timeBounds.minTime: 1000
        tx.timeBounds.maxTime: NOT_A_NUMBER
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 1000000
        tx.ext.v: 0
        signatures.len: 0
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("maxTime"), "Expected maxTime in key, got: \(key)")
            } else {
                XCTFail("Expected invalidValue for timeBounds.maxTime, got \(error)")
            }
        }
    }

    // MARK: - ChangeTrustAssetXDR compact .native arm (line 47)

    func testChangeTrustAssetNativeCompactToTxRep() throws {
        // Exercises the `.native` compact emit branch in ChangeTrustAssetXDR.toTxRep.
        var lines = [String]()
        try ChangeTrustAssetXDR.native.toTxRep(prefix: "changeTrustOp.line", lines: &lines)
        XCTAssertTrue(lines.contains("changeTrustOp.line: XLM"),
                      "ChangeTrustAssetXDR.native must emit compact 'XLM' line")
    }

    // MARK: - TrustlineAssetXDR compact .native arm (line 43)

    func testTrustlineAssetNativeCompactToTxRep() throws {
        // Exercises the `.native` compact emit branch in TrustlineAssetXDR.toTxRep.
        var lines = [String]()
        try TrustlineAssetXDR.native.toTxRep(prefix: "ledgerKey.trustLine.asset", lines: &lines)
        XCTAssertTrue(lines.contains("ledgerKey.trustLine.asset: XLM"),
                      "TrustlineAssetXDR.native must emit compact 'XLM' line")
    }

    // MARK: - LedgerKeyXDR CONFIG_SETTING and TTL arms

    func testLedgerKeyConfigSettingToAndFromTxRep() throws {
        // Exercises the CONFIG_SETTING arm in LedgerKeyXDR.toTxRep and fromTxRep.
        let configKey = LedgerKeyConfigSettingXDR(configSettingID: 3)
        let ledgerKey = LedgerKeyXDR.configSetting(configKey)

        var lines = [String]()
        try ledgerKey.toTxRep(prefix: "ledgerKey", lines: &lines)
        XCTAssertTrue(lines.contains("ledgerKey.type: CONFIG_SETTING"))
        XCTAssertTrue(lines.contains("ledgerKey.configSetting.configSettingID: 3"))

        var map = [String: String]()
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                map[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        let parsed = try LedgerKeyXDR.fromTxRep(map, prefix: "ledgerKey")
        if case .configSetting(let cs) = parsed {
            XCTAssertEqual(cs.configSettingID, 3)
        } else {
            XCTFail("Expected .configSetting LedgerKeyXDR")
        }
    }

    func testLedgerKeyTTLToAndFromTxRep() throws {
        // Exercises the TTL arm in LedgerKeyXDR.toTxRep and fromTxRep.
        let keyHash = WrappedData32(Data(repeating: 0xBB, count: 32))
        let ttlKey = LedgerKeyTTLXDR(keyHash: keyHash)
        let ledgerKey = LedgerKeyXDR.ttl(ttlKey)

        var lines = [String]()
        try ledgerKey.toTxRep(prefix: "ledgerKey", lines: &lines)
        XCTAssertTrue(lines.contains("ledgerKey.type: TTL"))
        XCTAssertTrue(lines.contains(where: { $0.hasPrefix("ledgerKey.ttl.keyHash:") }))

        var map = [String: String]()
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                map[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        let parsed = try LedgerKeyXDR.fromTxRep(map, prefix: "ledgerKey")
        if case .ttl(let t) = parsed {
            XCTAssertEqual(t.keyHash.wrapped, keyHash.wrapped)
        } else {
            XCTFail("Expected .ttl LedgerKeyXDR")
        }
    }

    // MARK: - Liquidity pool ID: hex and L-address StrKey decoding

    /// Verify that requireLiquidityPoolId accepts a 64-char lowercase hex string and
    /// produces the expected WrappedData32.
    func testRequireLiquidityPoolIdHexRoundtrip() throws {
        let poolHex = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        let map = ["pool.liquidityPoolID": poolHex]
        let result = try TxRepHelper.requireLiquidityPoolId(map, "pool.liquidityPoolID")
        XCTAssertEqual(result.wrapped.base16EncodedString(), poolHex)
    }

    /// Verify that requireLiquidityPoolId accepts an L-address StrKey and decodes
    /// to the same 32-byte value as the hex representation.
    func testRequireLiquidityPoolIdLAddressInput() throws {
        let poolHex = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        let poolData = Data(repeating: 0xBB, count: 32)
        let lAddress = try poolData.encodeLiquidityPoolId()
        XCTAssertTrue(lAddress.hasPrefix("L"), "L-address must start with L")

        let map = ["pool.liquidityPoolID": lAddress]
        let result = try TxRepHelper.requireLiquidityPoolId(map, "pool.liquidityPoolID")
        XCTAssertEqual(result.wrapped.base16EncodedString(), poolHex)
    }

    /// Verify that requireLiquidityPoolId throws missingValue when the key is absent.
    func testRequireLiquidityPoolIdMissingKeyThrows() throws {
        let map = [String: String]()
        XCTAssertThrowsError(try TxRepHelper.requireLiquidityPoolId(map, "pool.liquidityPoolID")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "pool.liquidityPoolID")
            } else {
                XCTFail("Expected missingValue(key:) error, got \(error)")
            }
        }
    }

    /// Verify that requireLiquidityPoolId throws invalidValue for an invalid input.
    func testRequireLiquidityPoolIdInvalidValueThrows() throws {
        let map = ["pool.liquidityPoolID": "not_valid_hex_or_laddress"]
        XCTAssertThrowsError(try TxRepHelper.requireLiquidityPoolId(map, "pool.liquidityPoolID")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertEqual(key, "pool.liquidityPoolID")
            } else {
                XCTFail("Expected invalidValue(key:) error, got \(error)")
            }
        }
    }

    /// Verify LedgerKeyLiquidityPoolXDR.fromTxRep roundtrip still works with hex input.
    func testLedgerKeyLiquidityPoolFromTxRepHexStillWorks() throws {
        let poolHex = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
        let map = ["lk.type": "LIQUIDITY_POOL", "lk.liquidityPool.liquidityPoolID": poolHex]
        let result = try LedgerKeyXDR.fromTxRep(map, prefix: "lk")
        if case .liquidityPool(let lp) = result {
            XCTAssertEqual(lp.liquidityPoolID.wrapped.base16EncodedString(), poolHex)
        } else {
            XCTFail("Expected .liquidityPool LedgerKeyXDR")
        }
    }

    /// Verify LedgerKeyLiquidityPoolXDR.fromTxRep accepts an L-address StrKey for liquidityPoolID.
    func testLedgerKeyLiquidityPoolFromTxRepLAddress() throws {
        let poolData = Data(repeating: 0xCC, count: 32)
        let poolHex = poolData.base16EncodedString()
        let lAddress = try poolData.encodeLiquidityPoolId()
        let map = ["lk.type": "LIQUIDITY_POOL", "lk.liquidityPool.liquidityPoolID": lAddress]
        let result = try LedgerKeyXDR.fromTxRep(map, prefix: "lk")
        if case .liquidityPool(let lp) = result {
            XCTAssertEqual(lp.liquidityPoolID.wrapped.base16EncodedString(), poolHex)
        } else {
            XCTFail("Expected .liquidityPool LedgerKeyXDR")
        }
    }

    /// Verify SCAddressXDR.fromTxRep accepts an L-address for the liquidityPoolId arm.
    func testSCAddressFromTxRepLiquidityPoolLAddress() throws {
        let poolData = Data(repeating: 0xDD, count: 32)
        let poolHex = poolData.base16EncodedString()
        let lAddress = try poolData.encodeLiquidityPoolId()
        let map = ["addr.type": "SC_ADDRESS_TYPE_LIQUIDITY_POOL", "addr.liquidityPoolId": lAddress]
        let result = try SCAddressXDR.fromTxRep(map, prefix: "addr")
        if case .liquidityPoolId(let wd) = result {
            XCTAssertEqual(wd.wrapped.base16EncodedString(), poolHex)
        } else {
            XCTFail("Expected .liquidityPoolId SCAddressXDR")
        }
    }

    /// Verify toTxRep for LedgerKeyLiquidityPoolXDR still emits hex (output path unchanged).
    func testLedgerKeyLiquidityPoolToTxRepEmitsHex() throws {
        let poolData = Data(repeating: 0xEE, count: 32)
        let poolHex = poolData.base16EncodedString()
        let lk = LedgerKeyLiquidityPoolXDR(liquidityPoolID: WrappedData32(poolData))
        var lines = [String]()
        try lk.toTxRep(prefix: "lk", lines: &lines)
        let poolLine = lines.first { $0.contains("liquidityPoolID:") }
        XCTAssertNotNil(poolLine, "Expected liquidityPoolID line in TxRep output")
        XCTAssertTrue(poolLine?.contains(poolHex) == true, "Expected hex output, got: \(poolLine ?? "nil")")
    }

    // MARK: - Zero-operation envelope roundtrips (P1 #1)

    func testV1ZeroOperationsRoundtrip() throws {
        // V1 envelope with 0 operations: toTxRep then fromTxRep must produce identical XDR.
        let source = try KeyPair(secretSeed: sourceSeed)
        let sourceAccount = MuxedAccountXDR.ed25519(source.publicKey.bytes)
        let tx = TransactionXDR(
            sourceAccount: sourceAccount,
            seqNum: 600_001,
            cond: .none,
            memo: .none,
            operations: [],
            maxOperationFee: 100
        )
        let envelope = TransactionV1EnvelopeXDR(tx: tx, signatures: [])
        let txEnvelope = TransactionEnvelopeXDR.v1(envelope)
        var encoded = try XDREncoder.encode(txEnvelope)
        let base64 = Data(bytes: &encoded, count: encoded.count).base64EncodedString()

        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("tx.operations.len: 0"), "toTxRep must emit operations.len: 0")

        let base64Again = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, base64Again, "V1 zero-operation envelope must roundtrip to identical XDR")
    }

    func testV0ZeroOperationsRoundtrip() throws {
        // V0 envelope with 0 operations: toTxRep then fromTxRep must produce identical XDR.
        let source = try KeyPair(secretSeed: sourceSeed)
        let v0Tx = TransactionV0XDR(
            sourceAccount: source.publicKey,
            seqNum: 600_002,
            timeBounds: nil,
            memo: .none,
            operations: [],
            maxOperationFee: 100
        )
        let v0Env = TransactionV0EnvelopeXDR(tx: v0Tx, signatures: [])
        let txEnvelope = TransactionEnvelopeXDR.v0(v0Env)
        var encoded = try XDREncoder.encode(txEnvelope)
        let base64 = Data(bytes: &encoded, count: encoded.count).base64EncodedString()

        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("tx.operations.len: 0"), "toTxRep must emit operations.len: 0")

        let base64Again = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, base64Again, "V0 zero-operation envelope must roundtrip to identical XDR")
    }

    // MARK: - Zero-signature envelope roundtrips (P2 #6)

    func testV1ZeroSignaturesRoundtrip() throws {
        // V1 envelope with 0 signatures: toTxRep then fromTxRep must produce identical XDR.
        let source = try KeyPair(secretSeed: sourceSeed)
        let dest = try KeyPair(accountId: destAccountId)
        let account = Account(keyPair: source, sequenceNumber: 700_000)
        let payment = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: dest.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: Decimal(10)
        )
        // Unsigned transaction — no sign() call.
        let tx = try Transaction(sourceAccount: account, operations: [payment], memo: Memo.none)
        let base64 = try tx.encodedEnvelope()

        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("signatures.len: 0"), "toTxRep must emit signatures.len: 0")

        let base64Again = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, base64Again, "V1 zero-signature envelope must roundtrip to identical XDR")
    }

    func testV0ZeroSignaturesRoundtrip() throws {
        // V0 envelope with 0 signatures: toTxRep then fromTxRep must produce identical XDR.
        let source = try KeyPair(secretSeed: sourceSeed)
        let dest = try KeyPair(accountId: destAccountId)
        let destMuxed = MuxedAccountXDR.ed25519(dest.publicKey.bytes)
        let payBody = OperationBodyXDR.paymentOp(PaymentOperationXDR(
            destination: destMuxed, asset: .native, amount: 100_000
        ))
        let op = OperationXDR(sourceAccount: MuxedAccountXDR?.none, body: payBody)
        let v0Tx = TransactionV0XDR(
            sourceAccount: source.publicKey,
            seqNum: 700_001,
            timeBounds: nil,
            memo: .none,
            operations: [op],
            maxOperationFee: 100
        )
        let v0Env = TransactionV0EnvelopeXDR(tx: v0Tx, signatures: [])
        let txEnvelope = TransactionEnvelopeXDR.v0(v0Env)
        var encoded = try XDREncoder.encode(txEnvelope)
        let base64 = Data(bytes: &encoded, count: encoded.count).base64EncodedString()

        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("signatures.len: 0"), "toTxRep must emit signatures.len: 0")

        let base64Again = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, base64Again, "V0 zero-signature envelope must roundtrip to identical XDR")
    }

    func testFeeBumpZeroInnerAndOuterSignaturesRoundtrip() throws {
        // Fee-bump with 0 inner signatures and 0 outer signatures must roundtrip.
        let feeSource = try KeyPair(secretSeed: sourceSeed)
        let innerSource = try KeyPair(accountId: destAccountId)
        let innerSourceMuxed = MuxedAccountXDR.ed25519(innerSource.publicKey.bytes)
        let dest = try KeyPair(secretSeed: sourceSeed)  // destination can be same for this test
        let destMuxed = MuxedAccountXDR.ed25519(dest.publicKey.bytes)
        let payBody = OperationBodyXDR.paymentOp(PaymentOperationXDR(
            destination: destMuxed, asset: .native, amount: 100_000
        ))
        let op = OperationXDR(sourceAccount: MuxedAccountXDR?.none, body: payBody)
        let innerTx = TransactionXDR(
            sourceAccount: innerSourceMuxed,
            seqNum: 700_002,
            cond: .none,
            memo: .none,
            operations: [op],
            maxOperationFee: 100
        )
        let innerEnvelope = TransactionV1EnvelopeXDR(tx: innerTx, signatures: [])
        let innerTxUnion = FeeBumpTransactionXDRInnerTxXDR.v1(innerEnvelope)
        let feeBumpTx = FeeBumpTransactionXDR(
            sourceAccount: MuxedAccountXDR.ed25519(feeSource.publicKey.bytes),
            innerTx: innerTxUnion,
            fee: 200
        )
        let feeBumpEnvelope = FeeBumpTransactionEnvelopeXDR(tx: feeBumpTx, signatures: [])
        let txEnvelope = TransactionEnvelopeXDR.feeBump(feeBumpEnvelope)
        var encoded = try XDREncoder.encode(txEnvelope)
        let base64 = Data(bytes: &encoded, count: encoded.count).base64EncodedString()

        let txRep = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRep.contains("feeBump.tx.innerTx.signatures.len: 0"),
                      "toTxRep must emit inner signatures.len: 0")
        XCTAssertTrue(txRep.contains("feeBump.signatures.len: 0"),
                      "toTxRep must emit outer signatures.len: 0")

        let base64Again = try TxRep.fromTxRep(txRep: txRep)
        XCTAssertEqual(base64, base64Again, "Fee-bump zero-signature envelope must roundtrip to identical XDR")
    }

    func testMissingSignaturesLenRoundtripProducesUnsignedEnvelope() throws {
        // A TxRep without signatures.len must parse to an unsigned V1 envelope,
        // and the subsequent toTxRep must emit signatures.len: 0.
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 700003
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 1000000
        tx.ext.v: 0
        """
        let base64 = try TxRep.fromTxRep(txRep: txRep)
        let txRepOut = try TxRep.toTxRep(transactionEnvelope: base64)
        XCTAssertTrue(txRepOut.contains("signatures.len: 0"),
                      "Round-tripped unsigned envelope must emit signatures.len: 0")
        let base64Again = try TxRep.fromTxRep(txRep: txRepOut)
        XCTAssertEqual(base64, base64Again, "Unsigned envelope must be stable across roundtrip")
    }

    func testSignaturesLenNotANumberThrows() throws {
        // A present but non-integer signatures.len must still throw invalidValue.
        let source = try KeyPair(secretSeed: sourceSeed)
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(source.accountId)
        tx.fee: 100
        tx.seqNum: 700004
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: PAYMENT
        tx.operations[0].body.paymentOp.destination: \(destAccountId)
        tx.operations[0].body.paymentOp.asset: XLM
        tx.operations[0].body.paymentOp.amount: 1000000
        tx.ext.v: 0
        signatures.len: not_a_number
        """
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertTrue(key.contains("signatures.len"),
                              "Expected signatures.len in error key, got: \(key)")
            } else {
                XCTFail("Expected invalidValue for malformed signatures.len, got \(error)")
            }
        }
    }

    // MARK: - Per-arm override require* error key correctness (P2 #9)

    /// Verify that a missing trustor for setTrustLineFlagsOp produces an error whose
    /// key contains the full field path (not an empty string).
    func testSetTrustLineFlagsOpMissingTrustorErrorKey() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(destAccountId)
        tx.fee: 100
        tx.seqNum: 100001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: SET_TRUST_LINE_FLAGS
        tx.operations[0].body.setTrustLineFlagsOp.asset: XLM
        tx.operations[0].body.setTrustLineFlagsOp.clearFlags: 0
        tx.operations[0].body.setTrustLineFlagsOp.setFlags: 1
        tx.ext.v: 0
        signatures.len: 0
        """

        // trustor key is missing — should throw with a non-empty key containing "trustor"
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            switch error {
            case TxRepError.missingValue(let key):
                XCTAssertFalse(key.isEmpty, "Error key must not be empty")
                XCTAssertTrue(key.contains("trustor"), "Expected key to contain 'trustor', got '\(key)'")
            case TxRepError.invalidValue(let key):
                XCTAssertFalse(key.isEmpty, "Error key must not be empty")
                XCTAssertTrue(key.contains("trustor"), "Expected key to contain 'trustor', got '\(key)'")
            default:
                XCTFail("Expected TxRepError for missing trustor, got \(error)")
            }
        }
    }

    /// Verify that an invalid trustor for setTrustLineFlagsOp produces an error whose
    /// key contains the full field path (not the invalid value string).
    func testSetTrustLineFlagsOpInvalidTrustorErrorKey() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(destAccountId)
        tx.fee: 100
        tx.seqNum: 100001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: SET_TRUST_LINE_FLAGS
        tx.operations[0].body.setTrustLineFlagsOp.trustor: NOT_A_VALID_ACCOUNT_ID
        tx.operations[0].body.setTrustLineFlagsOp.asset: XLM
        tx.operations[0].body.setTrustLineFlagsOp.clearFlags: 0
        tx.operations[0].body.setTrustLineFlagsOp.setFlags: 1
        tx.ext.v: 0
        signatures.len: 0
        """

        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertFalse(key.isEmpty, "Error key must not be empty")
                XCTAssertTrue(key.contains("trustor"), "Expected key to contain 'trustor', got '\(key)'")
            } else {
                XCTFail("Expected TxRepError.invalidValue for invalid trustor, got \(error)")
            }
        }
    }

    /// Verify that a missing sponsoredID for beginSponsoringFutureReservesOp produces
    /// an error key containing "sponsoredID" (not an empty string).
    func testBeginSponsoringFutureReservesOpMissingSponsoredIDErrorKey() throws {
        let txRep = """
        type: ENVELOPE_TYPE_TX
        tx.sourceAccount: \(destAccountId)
        tx.fee: 100
        tx.seqNum: 100001
        tx.cond.type: PRECOND_NONE
        tx.memo.type: MEMO_NONE
        tx.operations.len: 1
        tx.operations[0].sourceAccount._present: false
        tx.operations[0].body.type: BEGIN_SPONSORING_FUTURE_RESERVES
        tx.ext.v: 0
        signatures.len: 0
        """

        // sponsoredID key is missing — should throw with a non-empty key containing "sponsoredID"
        XCTAssertThrowsError(try TxRep.fromTxRep(txRep: txRep)) { error in
            switch error {
            case TxRepError.missingValue(let key):
                XCTAssertFalse(key.isEmpty, "Error key must not be empty")
                XCTAssertTrue(key.contains("sponsoredID"), "Expected key to contain 'sponsoredID', got '\(key)'")
            case TxRepError.invalidValue(let key):
                XCTAssertFalse(key.isEmpty, "Error key must not be empty")
                XCTAssertTrue(key.contains("sponsoredID"), "Expected key to contain 'sponsoredID', got '\(key)'")
            default:
                XCTFail("Expected TxRepError for missing sponsoredID, got \(error)")
            }
        }
    }
}
