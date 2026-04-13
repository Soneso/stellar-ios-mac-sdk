//
//  TxRepPathPaymentDirectTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//
//  Direct unit tests for PathPaymentOperationXDR.toTxRep / fromTxRep.
//  These exercise the generated methods directly, bypassing the TxRep facade
//  (which inlines path-payment arms via OperationBodyXDR.toTxRep). This is
//  intentional: the generated methods must remain correct public API even though
//  the facade does not route through them.
//

import XCTest
import stellarsdk

final class TxRepPathPaymentDirectTestCase: XCTestCase {

    // MARK: - Fixtures

    /// A well-known ed25519 account ID used across tests.
    private let accountId = "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR"

    /// A second account ID used as an issuer.
    private let issuerId = "GCMUFBSB6OB6R2MJKXB5G5UXZHE3XO4H5T4FNV2VDVMQRJZEQHWJFHZV"

    // MARK: - Helpers

    private func makeDestination() throws -> MuxedAccountXDR {
        let kp = try KeyPair(accountId: accountId)
        return MuxedAccountXDR.ed25519(kp.publicKey.bytes)
    }

    private func makeNativeAsset() -> AssetXDR {
        return .native
    }

    private func makeAlphanum4Asset(code: String) throws -> AssetXDR {
        let issuer = try KeyPair(accountId: issuerId).publicKey
        var codeBytes = code.utf8.prefix(4)
        var data = Data(codeBytes)
        while data.count < 4 { data.append(0) }
        let assetCode = WrappedData4(data)
        return .alphanum4(Alpha4XDR(assetCode: assetCode, issuer: issuer))
    }

    private func makeAlphanum12Asset(code: String) throws -> AssetXDR {
        let issuer = try KeyPair(accountId: issuerId).publicKey
        var data = Data(code.utf8.prefix(12))
        while data.count < 12 { data.append(0) }
        let assetCode = WrappedData12(data)
        return .alphanum12(Alpha12XDR(assetCode: assetCode, issuer: issuer))
    }

    private func buildOp(
        sendAsset: AssetXDR,
        sendMax: Int64 = 1_000_000,
        destinationAsset: AssetXDR,
        destinationAmount: Int64 = 500_000,
        path: [AssetXDR] = []
    ) throws -> PathPaymentOperationXDR {
        return PathPaymentOperationXDR(
            sendAsset: sendAsset,
            sendMax: sendMax,
            destination: try makeDestination(),
            destinationAsset: destinationAsset,
            destinationAmount: destinationAmount,
            path: path
        )
    }

    /// Round-trip helper: toTxRep → fromTxRep.
    private func roundtrip(_ op: PathPaymentOperationXDR) throws -> PathPaymentOperationXDR {
        var lines = [String]()
        try op.toTxRep(prefix: "op", lines: &lines)
        let text = lines.joined(separator: "\n")
        let map = TxRepHelper.parse(text)
        return try PathPaymentOperationXDR.fromTxRep(map, prefix: "op")
    }

    // MARK: - toTxRep output shape

    func testToTxRepEmptyPath() throws {
        let op = try buildOp(
            sendAsset: makeNativeAsset(),
            destinationAsset: try makeAlphanum4Asset(code: "USD"),
            path: []
        )
        var lines = [String]()
        try op.toTxRep(prefix: "op", lines: &lines)

        XCTAssertTrue(lines.contains("op.sendAsset: XLM"))
        XCTAssertTrue(lines.contains("op.sendMax: 1000000"))
        XCTAssertTrue(lines.contains("op.destination: \(accountId)"))
        XCTAssertTrue(lines.contains("op.path.len: 0"))
        // destAmount should be present
        XCTAssertTrue(lines.contains { $0.hasPrefix("op.destAmount:") })
    }

    func testToTxRepFullPath() throws {
        let path: [AssetXDR] = [
            makeNativeAsset(),
            try makeAlphanum4Asset(code: "EUR"),
            try makeAlphanum4Asset(code: "BTC"),
            try makeAlphanum12Asset(code: "LONGASSET0AB"),
            try makeAlphanum4Asset(code: "GBP"),
        ]
        let op = try buildOp(
            sendAsset: makeNativeAsset(),
            destinationAsset: try makeAlphanum4Asset(code: "USD"),
            path: path
        )
        var lines = [String]()
        try op.toTxRep(prefix: "op", lines: &lines)

        XCTAssertTrue(lines.contains("op.path.len: 5"))
        XCTAssertTrue(lines.contains { $0.hasPrefix("op.path[0]:") })
        XCTAssertTrue(lines.contains { $0.hasPrefix("op.path[4]:") })
        XCTAssertFalse(lines.contains { $0.hasPrefix("op.path[5]:") })
    }

    func testToTxRepAlphanum4SendAlphanum12Dest() throws {
        let op = try buildOp(
            sendAsset: try makeAlphanum4Asset(code: "USD"),
            destinationAsset: try makeAlphanum12Asset(code: "LONGASSET0AB"),
            path: []
        )
        var lines = [String]()
        try op.toTxRep(prefix: "myOp", lines: &lines)

        // Asset fields use compact CODE:ISSUER format (not expanded type discriminants)
        XCTAssertTrue(lines.contains { $0.hasPrefix("myOp.sendAsset:") && $0.contains("USD:") })
        XCTAssertTrue(lines.contains { $0.hasPrefix("myOp.destAsset:") && $0.contains("LONGASSET0AB:") })
    }

    // MARK: - fromTxRep parsing

    func testFromTxRepNativeToNativeEmptyPath() throws {
        let lines = """
        op.sendAsset: XLM
        op.sendMax: 2000000
        op.destination: \(accountId)
        op.destAsset: XLM
        op.destAmount: 1000000
        op.path.len: 0
        """
        let map = TxRepHelper.parse(lines)
        let op = try PathPaymentOperationXDR.fromTxRep(map, prefix: "op")

        XCTAssertEqual(op.sendMax, 2_000_000)
        XCTAssertEqual(op.destinationAmount, 1_000_000)
        XCTAssertEqual(op.path.count, 0)
        if case .native = op.sendAsset {} else { XCTFail("Expected native sendAsset") }
        if case .native = op.destinationAsset {} else { XCTFail("Expected native destinationAsset") }
    }

    func testFromTxRepWithOnePath() throws {
        // PathPaymentOperationXDR.toTxRep writes path assets using the compact CODE:ISSUER format.
        // Build a compact asset string for the path using TxRepHelper.formatAsset.
        let pathAsset = try makeAlphanum4Asset(code: "EUR")
        let compactPathAsset = TxRepHelper.formatAsset(pathAsset)

        let lines = """
        op.sendAsset: XLM
        op.sendMax: 5000000
        op.destination: \(accountId)
        op.destAsset: XLM
        op.destAmount: 4000000
        op.path.len: 1
        op.path[0]: \(compactPathAsset)
        """

        let map = TxRepHelper.parse(lines)
        let op = try PathPaymentOperationXDR.fromTxRep(map, prefix: "op")

        XCTAssertEqual(op.path.count, 1)
        if case .alphanum4 = op.path[0] {} else { XCTFail("Expected alphanum4 path asset") }
    }

    // MARK: - Roundtrip tests

    func testRoundtripNativeEmptyPath() throws {
        let original = try buildOp(
            sendAsset: makeNativeAsset(),
            sendMax: 12_345_678,
            destinationAsset: makeNativeAsset(),
            destinationAmount: 9_876_543,
            path: []
        )
        let restored = try roundtrip(original)

        XCTAssertEqual(restored.sendMax, original.sendMax)
        XCTAssertEqual(restored.destinationAmount, original.destinationAmount)
        XCTAssertEqual(restored.path.count, 0)
        if case .native = restored.sendAsset {} else { XCTFail("sendAsset mismatch") }
        if case .native = restored.destinationAsset {} else { XCTFail("destinationAsset mismatch") }
    }

    func testRoundtripAlphanum4ToAlphanum4WithPath() throws {
        let path: [AssetXDR] = [
            makeNativeAsset(),
            try makeAlphanum4Asset(code: "EUR"),
        ]
        let original = try buildOp(
            sendAsset: try makeAlphanum4Asset(code: "USD"),
            sendMax: 999_999,
            destinationAsset: try makeAlphanum4Asset(code: "GBP"),
            destinationAmount: 888_888,
            path: path
        )
        let restored = try roundtrip(original)

        XCTAssertEqual(restored.sendMax, original.sendMax)
        XCTAssertEqual(restored.destinationAmount, original.destinationAmount)
        XCTAssertEqual(restored.path.count, 2)
        if case .alphanum4 = restored.sendAsset {} else { XCTFail("sendAsset mismatch") }
        if case .alphanum4 = restored.destinationAsset {} else { XCTFail("destinationAsset mismatch") }
        if case .native = restored.path[0] {} else { XCTFail("path[0] should be native") }
        if case .alphanum4 = restored.path[1] {} else { XCTFail("path[1] should be alphanum4") }
    }

    func testRoundtripAlphanum12Assets() throws {
        let original = try buildOp(
            sendAsset: try makeAlphanum12Asset(code: "LONGASSET0AB"),
            sendMax: 1_111_111,
            destinationAsset: try makeAlphanum12Asset(code: "OTHERASSET12"),
            destinationAmount: 222_222,
            path: []
        )
        let restored = try roundtrip(original)

        XCTAssertEqual(restored.sendMax, original.sendMax)
        XCTAssertEqual(restored.destinationAmount, original.destinationAmount)
        if case .alphanum12 = restored.sendAsset {} else { XCTFail("sendAsset should be alphanum12") }
        if case .alphanum12 = restored.destinationAsset {} else { XCTFail("destinationAsset should be alphanum12") }
    }

    func testRoundtripFivePathAssets() throws {
        let path: [AssetXDR] = [
            makeNativeAsset(),
            try makeAlphanum4Asset(code: "EUR"),
            try makeAlphanum12Asset(code: "CRYPTOABC123"),
            try makeAlphanum4Asset(code: "BTC"),
            makeNativeAsset(),
        ]
        let original = try buildOp(
            sendAsset: makeNativeAsset(),
            destinationAsset: try makeAlphanum4Asset(code: "USD"),
            path: path
        )
        let restored = try roundtrip(original)

        XCTAssertEqual(restored.path.count, 5)
        if case .native = restored.path[0] {} else { XCTFail("path[0] mismatch") }
        if case .alphanum4 = restored.path[1] {} else { XCTFail("path[1] mismatch") }
        if case .alphanum12 = restored.path[2] {} else { XCTFail("path[2] mismatch") }
        if case .alphanum4 = restored.path[3] {} else { XCTFail("path[3] mismatch") }
        if case .native = restored.path[4] {} else { XCTFail("path[4] mismatch") }
    }

    func testRoundtripDestinationAccountIdPreserved() throws {
        let original = try buildOp(
            sendAsset: makeNativeAsset(),
            destinationAsset: makeNativeAsset()
        )
        let restored = try roundtrip(original)
        XCTAssertEqual(restored.destination.ed25519AccountId, accountId)
    }

    // MARK: - Error paths: fromTxRep with missing required keys

    func testFromTxRepMissingSendAssetTypeThrows() {
        // Omit sendAsset.type entirely — requireAsset should throw .missingValue
        let lines = """
        op.sendMax: 1000000
        op.destination: \(accountId)
        op.destAsset: XLM
        op.destAmount: 500000
        op.path.len: 0
        """
        let map = TxRepHelper.parse(lines)
        XCTAssertThrowsError(try PathPaymentOperationXDR.fromTxRep(map, prefix: "op"))
    }

    func testFromTxRepMissingDestAssetTypeThrows() {
        let lines = """
        op.sendAsset: XLM
        op.sendMax: 1000000
        op.destination: \(accountId)
        op.destAmount: 500000
        op.path.len: 0
        """
        let map = TxRepHelper.parse(lines)
        XCTAssertThrowsError(try PathPaymentOperationXDR.fromTxRep(map, prefix: "op"))
    }

    func testFromTxRepMissingDestinationThrows() {
        // destination key absent — requireMuxedAccount should throw
        let lines = """
        op.sendAsset: XLM
        op.sendMax: 1000000
        op.destAsset: XLM
        op.destAmount: 500000
        op.path.len: 0
        """
        let map = TxRepHelper.parse(lines)
        XCTAssertThrowsError(try PathPaymentOperationXDR.fromTxRep(map, prefix: "op"))
    }

    func testFromTxRepInvalidPathAssetThrows() {
        // path.len says 1 but path[0] value is empty, causing parseAsset to throw
        let lines = """
        op.sendAsset: XLM
        op.sendMax: 1000000
        op.destination: \(accountId)
        op.destAsset: XLM
        op.destAmount: 500000
        op.path.len: 1
        """
        let map = TxRepHelper.parse(lines)
        XCTAssertThrowsError(try PathPaymentOperationXDR.fromTxRep(map, prefix: "op"))
    }

    func testFromTxRepInvalidSendMaxThrows() {
        // sendMax has a non-numeric value so parseInt64 throws
        let lines = """
        op.sendAsset: XLM
        op.sendMax: NOT_A_NUMBER
        op.destination: \(accountId)
        op.destAsset: XLM
        op.destAmount: 500000
        op.path.len: 0
        """
        let map = TxRepHelper.parse(lines)
        XCTAssertThrowsError(try PathPaymentOperationXDR.fromTxRep(map, prefix: "op"))
    }

    func testFromTxRepInvalidDestAmountThrows() {
        // destAmount is non-numeric so parseInt64 throws
        let lines = """
        op.sendAsset: XLM
        op.sendMax: 1000000
        op.destination: \(accountId)
        op.destAsset: XLM
        op.destAmount: INVALID
        op.path.len: 0
        """
        let map = TxRepHelper.parse(lines)
        XCTAssertThrowsError(try PathPaymentOperationXDR.fromTxRep(map, prefix: "op"))
    }

    func testFromTxRepInvalidPathLenThrows() {
        // path.len is non-numeric so parseInt throws
        let lines = """
        op.sendAsset: XLM
        op.sendMax: 1000000
        op.destination: \(accountId)
        op.destAsset: XLM
        op.destAmount: 500000
        op.path.len: NOT_A_NUMBER
        """
        let map = TxRepHelper.parse(lines)
        XCTAssertThrowsError(try PathPaymentOperationXDR.fromTxRep(map, prefix: "op"))
    }

    func testFromTxRepMalformedPathAssetStringThrows() {
        // path[0] is present but not parseable as an asset (no colon, not XLM)
        let lines = """
        op.sendAsset: XLM
        op.sendMax: 1000000
        op.destination: \(accountId)
        op.destAsset: XLM
        op.destAmount: 500000
        op.path.len: 1
        op.path[0]: NOTANASSET
        """
        let map = TxRepHelper.parse(lines)
        XCTAssertThrowsError(try PathPaymentOperationXDR.fromTxRep(map, prefix: "op"))
    }

    // MARK: - Missing optional keys: exercises the `?? "0"` default branches

    func testFromTxRepMissingSendMaxUsesZeroDefault() throws {
        // sendMax key is absent; getValue returns nil so parseInt64 receives "0" (== 0).
        let lines = """
        op.sendAsset: XLM
        op.destination: \(accountId)
        op.destAsset: XLM
        op.destAmount: 500000
        op.path.len: 0
        """
        let map = TxRepHelper.parse(lines)
        let op = try PathPaymentOperationXDR.fromTxRep(map, prefix: "op")
        XCTAssertEqual(op.sendMax, 0)
    }

    func testFromTxRepMissingDestAmountUsesZeroDefault() throws {
        // destAmount key is absent; getValue returns nil so parseInt64 receives "0".
        let lines = """
        op.sendAsset: XLM
        op.sendMax: 1000000
        op.destination: \(accountId)
        op.destAsset: XLM
        op.path.len: 0
        """
        let map = TxRepHelper.parse(lines)
        let op = try PathPaymentOperationXDR.fromTxRep(map, prefix: "op")
        XCTAssertEqual(op.destinationAmount, 0)
    }

    func testFromTxRepMissingPathLenUsesZeroDefault() throws {
        // path.len key is absent; getValue returns nil so parseInt receives "0" and loop is empty.
        let lines = """
        op.sendAsset: XLM
        op.sendMax: 1000000
        op.destination: \(accountId)
        op.destAsset: XLM
        op.destAmount: 500000
        """
        let map = TxRepHelper.parse(lines)
        let op = try PathPaymentOperationXDR.fromTxRep(map, prefix: "op")
        XCTAssertEqual(op.path.count, 0)
    }
}
