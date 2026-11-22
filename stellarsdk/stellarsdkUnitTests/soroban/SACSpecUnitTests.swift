//
//  SACSpecUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 22.11.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Tests the embedded Stellar Asset Contract spec and its decoder.
///
/// The expected commit, digest, size, and names are those of the pinned upstream spec file. A
/// new pin, or a changed function or event set, fails these tests until the expected values
/// follow.
final class SACSpecUnitTests: XCTestCase {

    /// One `functionV0` entry: an empty doc, the name `balance`, no inputs, and no outputs.
    private let functionEntry: [UInt8] = [
        0, 0, 0, 0, // kind: function_v0
        0, 0, 0, 0, // doc: length 0
        0, 0, 0, 7, // name: length 7
        0x62, 0x61, 0x6c, 0x61, 0x6e, 0x63, 0x65, 0, // "balance" and one padding byte
        0, 0, 0, 0, // inputs: none
        0, 0, 0, 0, // outputs: none
    ]

    private func sha256Hex(_ bytes: [UInt8]) -> String {
        return Data(bytes).sha256Hash.base16EncodedString()
    }

    /// Decodes `bytes` with their own sha256, so only the entry decoding can fail.
    private func decode(_ bytes: [UInt8]) throws -> [SCSpecEntryXDR] {
        return try SACClient.decodeSpec(base64: Data(bytes).base64EncodedString(), sha256Hex: sha256Hex(bytes))
    }

    private func assertDecodingError(_ expectedMessage: String,
                                     file: StaticString = #filePath,
                                     line: UInt = #line,
                                     _ decoding: () throws -> [SCSpecEntryXDR]) {
        XCTAssertThrowsError(try decoding(), file: file, line: line) { error in
            guard case StellarSDKError.xdrDecodingError(let message) = error else {
                XCTFail("expected StellarSDKError.xdrDecodingError, got \(error)", file: file, line: line)
                return
            }
            XCTAssertEqual(message, expectedMessage, file: file, line: line)
        }
    }

    private func typeName(_ type: SCSpecTypeDefXDR) -> String {
        switch type {
        case .address: return "address"
        case .muxedAddress: return "muxedAddress"
        case .i128: return "i128"
        case .u32: return "u32"
        case .string: return "string"
        default: return "another type"
        }
    }

    private func function(_ name: String, in entries: [SCSpecEntryXDR]) throws -> SCSpecFunctionV0XDR {
        let matches = entries.compactMap { entry -> SCSpecFunctionV0XDR? in
            if case .functionV0(let function) = entry, function.name == name {
                return function
            }
            return nil
        }
        XCTAssertEqual(matches.count, 1, "functions named \(name)")
        return try XCTUnwrap(matches.first)
    }

    // MARK: - The embedded constants

    func testEmbeddedConstants() throws {
        XCTAssertEqual(SACSpec.UPSTREAM_COMMIT, "4f08d14f8b3e09e195f2cc4aab51c7f8a34f52ea")
        XCTAssertEqual(SACSpec.SHA256, "a88030febc66645d40b96deba8be16a6eb13c213768b4c1f9cd6278080d74669")
        XCTAssertEqual(SACSpec.XDR_BASE64.count, 12816)

        let bytes = try XCTUnwrap(Data(base64Encoded: SACSpec.XDR_BASE64))
        XCTAssertEqual(bytes.count, 9612)
        XCTAssertEqual(bytes.sha256Hash.base16EncodedString(), SACSpec.SHA256)
    }

    // MARK: - The entries

    func testSpecEntriesAreTheFunctionsAndEventsOfTheContract() throws {
        let entries = try SACClient.specEntries()
        XCTAssertEqual(entries.count, 30)

        var functionNames: [String] = []
        var eventNames: [String] = []
        for entry in entries {
            switch entry {
            case .functionV0(let function):
                functionNames.append(function.name)
            case .eventV0(let event):
                eventNames.append(event.name)
            default:
                XCTFail("an entry is neither a function nor an event")
            }
        }
        XCTAssertEqual(functionNames.sorted(), [
            "admin", "allowance", "approve", "authorized", "balance", "burn", "burn_from", "clawback",
            "decimals", "mint", "name", "set_admin", "set_authorized", "symbol", "transfer",
            "transfer_from", "trust",
        ])
        XCTAssertEqual(eventNames.sorted(), [
            "Approve", "Burn", "Clawback", "Mint", "MintWithAmountOnly", "MintWithMuxedBytes",
            "MintWithMuxedString", "SetAdmin", "SetAuthorized", "Transfer", "TransferWithAmountOnly",
            "TransferWithMuxedBytes", "TransferWithMuxedString",
        ])
    }

    func testSpecEntriesReencodeToTheEmbeddedBytes() throws {
        let bytes = try XCTUnwrap(Data(base64Encoded: SACSpec.XDR_BASE64))
        var reencoded: [UInt8] = []
        for entry in try SACClient.specEntries() {
            reencoded += try XDREncoder.encode(entry)
        }
        XCTAssertEqual(reencoded, [UInt8](bytes))
    }

    func testFunctionSignatures() throws {
        let entries = try SACClient.specEntries()

        let balance = try function("balance", in: entries)
        XCTAssertEqual(balance.inputs.map { "\($0.name): \(typeName($0.type))" }, ["id: address"])
        XCTAssertEqual(balance.outputs.map { typeName($0) }, ["i128"])

        let decimals = try function("decimals", in: entries)
        XCTAssertEqual(decimals.inputs.map { "\($0.name): \(typeName($0.type))" }, [])
        XCTAssertEqual(decimals.outputs.map { typeName($0) }, ["u32"])

        let name = try function("name", in: entries)
        XCTAssertEqual(name.inputs.map { "\($0.name): \(typeName($0.type))" }, [])
        XCTAssertEqual(name.outputs.map { typeName($0) }, ["string"])

        let symbol = try function("symbol", in: entries)
        XCTAssertEqual(symbol.inputs.map { "\($0.name): \(typeName($0.type))" }, [])
        XCTAssertEqual(symbol.outputs.map { typeName($0) }, ["string"])

        let transfer = try function("transfer", in: entries)
        XCTAssertEqual(transfer.inputs.map { "\($0.name): \(typeName($0.type))" },
                       ["from: address", "to: muxedAddress", "amount: i128"])
        XCTAssertEqual(transfer.outputs.map { typeName($0) }, [])
    }

    // MARK: - The decoder's failures

    func testDecodeSpecRejectsInvalidBase64() {
        assertDecodingError("The embedded SAC spec is not valid base64") {
            try SACClient.decodeSpec(base64: "@@@@", sha256Hex: SACSpec.SHA256)
        }
    }

    func testDecodeSpecRejectsAnotherSha256() throws {
        let truncated = String(SACSpec.XDR_BASE64.dropLast(4))
        let actual = try XCTUnwrap(Data(base64Encoded: truncated)).sha256Hash.base16EncodedString()
        XCTAssertNotEqual(actual, SACSpec.SHA256)

        assertDecodingError("The embedded SAC spec has sha256 \(actual), expected a88030febc66645d40b96deba8be16a6eb13c213768b4c1f9cd6278080d74669") {
            try SACClient.decodeSpec(base64: truncated, sha256Hex: SACSpec.SHA256)
        }
    }

    func testDecodeSpecNamesTheOffsetOfTrailingBytes() throws {
        let bytes = [UInt8](try XCTUnwrap(Data(base64Encoded: SACSpec.XDR_BASE64))) + [0xFF, 0xFF, 0xFF, 0xFF]
        let inner = StellarSDKError.xdrDecodingError(message: "Unknown SCSpecEntryXDR discriminant: -1")

        assertDecodingError("The embedded SAC spec does not decode at byte offset 9612: \(String(describing: inner))") {
            try decode(bytes)
        }
    }

    func testDecodeSpecDecodesOneEntry() throws {
        XCTAssertEqual(functionEntry.count, 28)
        let entries = try decode(functionEntry)
        XCTAssertEqual(entries.count, 1)
        guard case .functionV0(let function) = try XCTUnwrap(entries.first) else {
            XCTFail("expected a function entry")
            return
        }
        XCTAssertEqual(function.doc, "")
        XCTAssertEqual(function.name, "balance")
        XCTAssertEqual(function.inputs.count, 0)
        XCTAssertEqual(function.outputs.count, 0)
    }

    func testDecodeSpecRejectsANonZeroPaddingByte() {
        var bytes = functionEntry
        XCTAssertEqual(bytes[19], 0)
        bytes[19] = 1

        assertDecodingError("The embedded SAC spec does not decode at byte offset 0: the entry re-encodes to different bytes") {
            try decode(bytes)
        }
    }

    func testDecodeSpecRejectsATruncatedEntry() {
        let bytes = Array(functionEntry.dropLast(2))
        let inner = XDRDecoder.Error.prematureEndOfData

        assertDecodingError("The embedded SAC spec does not decode at byte offset 0: \(String(describing: inner))") {
            try decode(bytes)
        }
    }

    func testDecodeSpecRejectsAnUnknownEntryKind() {
        let bytes: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF] + functionEntry.dropFirst(4)
        let inner = StellarSDKError.xdrDecodingError(message: "Unknown SCSpecEntryXDR discriminant: -1")

        assertDecodingError("The embedded SAC spec does not decode at byte offset 0: \(String(describing: inner))") {
            try decode(bytes)
        }
    }
}
