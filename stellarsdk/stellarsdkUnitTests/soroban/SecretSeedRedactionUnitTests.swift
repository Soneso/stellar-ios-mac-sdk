//
//  SecretSeedRedactionUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 12.11.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Error texts never show a secret seed or a near miss of one, and show every other input
/// as they do for any invalid value.
final class SecretSeedRedactionUnitTests: XCTestCase {

    private let seedText = "a secret seed (S...)"
    private let sValueText = "a value starting with S (not shown, it may be a secret seed)"
    private let accountG = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
    private let addressTakes = "Address takes an account (G...) or contract (C...) address"
    private let muxedAddressTakes = "MuxedAddress takes an account (G...), muxed account (M...), contract (C...) or muxed contract (W...) address"
    private var variants: SeedVariants!

    override func setUpWithError() throws {
        try super.setUpWithError()
        variants = try SeedVariants()
    }

    /// The text a key position shows for a variant: the seed wording for the valid seed,
    /// the S value wording for every near miss.
    private func keyText(_ variant: String) -> String {
        return variant == variants.seed ? seedText : sValueText
    }

    /// `variant` behind as many leading spaces as fill the 64 characters of a hex id.
    private func padded(_ variant: String) -> String {
        return String(repeating: " ", count: 64 - variant.count) + variant
    }

    // MARK: - Rule for key positions

    func testNearMissesAreNoValidSecretSeeds() {
        XCTAssertTrue(variants.seed.isValidEd25519SecretSeed())
        for nearMiss in variants.nearMisses {
            XCTAssertFalse(nearMiss.isValidEd25519SecretSeed())
            XCTAssertTrue(nearMiss.hasPrefix("S") || nearMiss.hasPrefix("s"))
        }
    }

    func testSeedKindNamesEveryValueStartingWithS() {
        XCTAssertEqual(SecretSeedRedaction.seedKind(of: variants.seed), seedText)
        XCTAssertEqual(SecretSeedRedaction.seedKind(of: " \t\(variants.seed)\n"), seedText)
        for nearMiss in variants.nearMisses {
            XCTAssertEqual(SecretSeedRedaction.seedKind(of: nearMiss), sValueText)
        }
        XCTAssertEqual(SecretSeedRedaction.seedKind(of: "S"), sValueText)
        XCTAssertEqual(SecretSeedRedaction.seedKind(of: "  sun"), sValueText)
    }

    func testSeedKindIsNilForEveryOtherValue() throws {
        let contractC = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"
        let muxedM = try MuxedAccount(accountId: accountG, id: 7).accountId
        let muxedW = try MuxedContract(contractId: contractC, id: 7).address
        XCTAssertTrue(muxedM.hasPrefix("M"))
        XCTAssertTrue(muxedW.hasPrefix("W"))
        let poolId = "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9"
        let others = ["", "   ", accountG, muxedM, contractC, muxedW, poolId, "100.5", "-0.0000001",
                      "123456", "native", "12345", "XLM", "a value with S inside"]
        for value in others {
            XCTAssertNil(SecretSeedRedaction.seedKind(of: value), value)
            XCTAssertEqual(SecretSeedRedaction.keyPositionText(value), value)
        }
    }

    func testKeyPositionTextNamesTheKindOfEveryVariant() {
        for variant in variants.all {
            XCTAssertEqual(SecretSeedRedaction.keyPositionText(variant), keyText(variant))
        }
    }

    // MARK: - Rule for free positions and wrapped texts

    func testRedactionReplacesEveryVariant() {
        for variant in variants.all {
            XCTAssertEqual(SecretSeedRedaction.redactingSecretSeeds(in: "amount \(variant) given"),
                           "amount \(seedText) given")
        }
        XCTAssertEqual(SecretSeedRedaction.redactingSecretSeeds(in: "key=\(variants.seed);\(variants.lowercase)"),
                       "key=\(seedText);\(seedText)")
    }

    func testRedactionStartsAtFortyCharacters() {
        let thirtyNine = "S" + String(repeating: "A", count: 38)
        let forty = "S" + String(repeating: "A", count: 39)
        let fortyLowercase = "s" + String(repeating: "7", count: 39)
        XCTAssertEqual(SecretSeedRedaction.redactingSecretSeeds(in: "(\(thirtyNine))"), "(\(thirtyNine))")
        XCTAssertEqual(SecretSeedRedaction.redactingSecretSeeds(in: "(\(forty))"), "(\(seedText))")
        XCTAssertEqual(SecretSeedRedaction.redactingSecretSeeds(in: "(\(fortyLowercase))"), "(\(seedText))")
    }

    func testRedactionKeepsShortRunsAndTakesLongRunsThatStartWithS() {
        let sentence = "Send SRT to Stellar, a 12345678901234567890123456789012345678901234567890 digit run"
        XCTAssertEqual(SecretSeedRedaction.redactingSecretSeeds(in: sentence), sentence)
        let base64Run = "AAAA+S" + String(repeating: "Q", count: 44)
        XCTAssertEqual(SecretSeedRedaction.redactingSecretSeeds(in: base64Run), "AAAA+\(seedText)")
        XCTAssertEqual(SecretSeedRedaction.redactingSecretSeeds(in: "(S\(variants.seed))"), "(\(seedText))")
    }

    func testRedactionTakesAValidSeedGluedToOtherCharacters() {
        let seed = variants.seed
        let mixedCase = String(seed.enumerated().map { $0.offset % 2 == 0 ? Character($0.element.lowercased()) : $0.element })
        let cases = [
            ("x" + seed, "x" + seedText),
            ("7" + seed, "7" + seedText),
            ("xS" + seed, "xS" + seedText),
            ("x" + variants.lowercase, "x" + seedText),
            ("x" + mixedCase, "x" + seedText),
            ("ab" + seed + "cd", "ab" + seedText + "cd"),
            ("x" + seed + seed, "x" + seedText + seedText),
            ("key=x\(seed) given", "key=x\(seedText) given"),
        ]
        for (text, expected) in cases {
            XCTAssertEqual(SecretSeedRedaction.redactingSecretSeeds(in: text), expected)
        }
    }

    // MARK: - Key position sites

    func testMuxedContractNeverShowsASeed() {
        for variant in variants.all {
            assertInvalidArgument(try MuxedContract(contractId: variant, id: 1),
                                  "not a contract id (C...): \(keyText(variant))")
            assertInvalidArgument(try MuxedContract(address: variant),
                                  "not a contract (C...) or muxed contract (W...) address: \(keyText(variant))")
        }
        assertInvalidArgument(try MuxedContract(contractId: accountG, id: 1), "not a contract id (C...): \(accountG)")
        assertInvalidArgument(try MuxedContract(address: "not an address"),
                              "not a contract (C...) or muxed contract (W...) address: not an address")
    }

    func testContractSpecAddressNeverShowsASeed() {
        for (ty, takes) in [(SCSpecTypeDefXDR.address, addressTakes), (.muxedAddress, muxedAddressTakes)] {
            for variant in variants.all {
                assertInvalidType(variant, ty, "Invalid address format: \(keyText(variant)); \(takes)")
            }
            assertInvalidType("XA7QYNF7", ty, "Invalid address format: XA7QYNF7; \(takes)")
        }
    }

    func testDelegateAddressNeverShowsASeed() {
        for variant in variants.all {
            assertInvalidArgument(try scAddressXDR(fromStrkey: variant),
                                  "Unsupported strkey prefix for delegate address: \(keyText(variant))")
        }
        assertInvalidArgument(try scAddressXDR(fromStrkey: "XA7QYNF7"),
                              "Unsupported strkey prefix for delegate address: XA7QYNF7")
    }

    func testHexIdEncodersNeverShowASeed() {
        for variant in variants.all {
            assertInvalidArgument(try variant.encodeContractIdHex(),
                                  "invalid contract id, not a hex string \(keyText(variant))")
            assertInvalidArgument(try variant.encodeClaimableBalanceIdHex(),
                                  "invalid claimable balance id, not a hex string \(keyText(variant))")
            assertInvalidArgument(try variant.encodeLiquidityPoolIdHex(),
                                  "invalid liquidity pool id, not a hex string \(keyText(variant))")
        }
        assertInvalidArgument(try "ZZZZ".encodeContractIdHex(), "invalid contract id, not a hex string ZZZZ")
        assertInvalidArgument(try "ZZZZ".encodeClaimableBalanceIdHex(), "invalid claimable balance id, not a hex string ZZZZ")
        assertInvalidArgument(try "ZZZZ".encodeLiquidityPoolIdHex(), "invalid liquidity pool id, not a hex string ZZZZ")
    }

    /// A padded value has the 64 characters of a hex id and so reaches the alphabet check.
    func testHexIdReaderNeverShowsAPaddedSeed() {
        for variant in variants.all {
            let input = padded(variant)
            assertInvalidArgument(try SCAddressXDR(contractId: input), "invalid contract id, not a hex string \(keyText(variant))")
            assertInvalidArgument(try SCAddressXDR(liquidityPoolId: input),
                                  "invalid liquidity pool id, not a hex string \(keyText(variant))")
            assertInvalidArgument(try LedgerKeyContractCodeXDR(wasmId: input), "invalid wasm id, not a hex string \(keyText(variant))")
        }
        let trailing = variants.seed + String(repeating: "\n", count: 8)
        assertInvalidArgument(try SCAddressXDR(contractId: trailing), "invalid contract id, not a hex string \(seedText)")
        let notHex = String(repeating: "z", count: 64)
        assertInvalidArgument(try SCAddressXDR(contractId: notHex), "invalid contract id, not a hex string \(notHex)")
    }

    func testTxRepKeyParsersNeverStoreASeed() {
        for variant in variants.all {
            for input in [variant, padded(variant)] {
                let shown = keyText(variant)
                assertInvalidValue(try TxRepHelper.parseAccountId(input), key: shown, hiding: variant)
                assertInvalidValue(try TxRepHelper.parseMuxedAccount(input), key: shown, hiding: variant)
                assertInvalidValue(try TxRepHelper.parseAsset("USD:\(input)"), key: shown, hiding: variant)
                assertInvalidValue(try TxRepHelper.parseSignerKey(input), key: shown, hiding: variant)
                assertInvalidValue(try TxRepHelper.parseLiquidityPoolId(input), key: shown, hiding: variant)
                assertInvalidValue(try TxRepHelper.hexToBytes(input), key: shown, hiding: variant)
            }
        }
        assertInvalidValue(try TxRepHelper.parseAccountId("GA7QYNF7"), key: "GA7QYNF7", hiding: nil)
        assertInvalidValue(try TxRepHelper.parseMuxedAccount("MA7QYNF7"), key: "MA7QYNF7", hiding: nil)
        assertInvalidValue(try TxRepHelper.parseSignerKey("QA7QYNF7"), key: "QA7QYNF7", hiding: nil)
        assertInvalidValue(try TxRepHelper.parseLiquidityPoolId("QA7QYNF7"), key: "QA7QYNF7", hiding: nil)
        assertInvalidValue(try TxRepHelper.hexToBytes("12zz"), key: "12zz", hiding: nil)
    }

    func testContractIdRefusalNamesEveryVariantByKind() {
        let refusal = "The contract to invoke must be a contract (C...) address"
        for variant in variants.all {
            XCTAssertEqual(ContractAddressGuard.contractIdRefusal(variant, subject: "The contract to invoke"),
                           "\(refusal), got \(keyText(variant)) instead of an address")
            assertInvalidArgument(try InvokeHostFunctionOperation.forInvokingContract(contractId: variant, functionName: "hello"),
                                  "\(refusal), got \(keyText(variant)) instead of an address")
        }
        XCTAssertEqual(ContractAddressGuard.contractIdRefusal(" \(variants.seed)\n", subject: "The contract to invoke"),
                       "\(refusal), got \(seedText) instead of an address")
        XCTAssertEqual(ContractAddressGuard.contractIdRefusal("not a contract", subject: "The contract to invoke"),
                       "\(refusal): not a contract")
        XCTAssertEqual(ContractAddressGuard.contractIdRefusal(accountG, subject: "The contract to invoke"),
                       "\(refusal), got an account (G...) address: \(accountG)")
    }

    // MARK: - Free position sites

    func testContractSpecIntegerStringNeverShowsASeed() {
        for variant in variants.all {
            assertInvalidType(variant, .u64, "String value \"\(seedText)\" is not a decimal integer that fits u64")
        }
        assertInvalidType("12a", .u64, "String value \"12a\" is not a decimal integer that fits u64")
    }

    func testWideIntegerStringNeverShowsASeed() {
        let spec = ContractSpec(entries: [])
        for variant in variants.all {
            assertInvalidArgument(try SCValXDR.u128(stringValue: variant), "Invalid number string: \(seedText)")
            assertInvalidArgument(try spec.nativeToXdrSCVal(val: variant, ty: .i256), "Invalid number string: \(seedText)")
        }
        assertInvalidArgument(try SCValXDR.u128(stringValue: "1" + variants.seed), "Invalid number string: 1\(seedText)")
        assertInvalidArgument(try SCValXDR.i128(stringValue: "12x"), "Invalid number string: 12x")
    }

    func testUnionTagNeverShowsASeed() {
        let cases = [SCSpecUDTUnionCaseV0XDR.voidV0(SCSpecUDTUnionCaseVoidV0XDR(doc: "", name: "none"))]
        let spec = ContractSpec(entries: [.unionV0(SCSpecUDTUnionV0XDR(doc: "", lib: "", name: "MyUnion", cases: cases))])
        let unionType = SCSpecTypeDefXDR.udt(SCSpecTypeUDTXDR(name: "MyUnion"))
        for variant in variants.all {
            assertInvalidEnumValue(try spec.nativeToXdrSCVal(val: NativeUnionVal(tag: variant), ty: unionType),
                                   "No such union entry: \(seedText) in MyUnion")
        }
        assertInvalidEnumValue(try spec.nativeToXdrSCVal(val: NativeUnionVal(tag: "some"), ty: unionType),
                               "No such union entry: some in MyUnion")
    }

    func testTxRepNumberParsersNeverStoreASeed() {
        let parsers: [(String) throws -> Void] = [
            { _ = try TxRepHelper.parseInt($0) },
            { _ = try TxRepHelper.parseInt64($0) },
            { _ = try TxRepHelper.parseUInt64($0) },
        ]
        for parse in parsers {
            for variant in variants.all {
                // No prefix reaches the decimal branch, "--" the sign check and "0x " the hex branch.
                for prefix in ["", "--", "0x "] {
                    assertInvalidValue(try parse(prefix + variant), key: prefix + seedText, hiding: variant)
                }
            }
            assertInvalidValue(try parse("0x" + variants.seed), key: "0x" + seedText, hiding: variants.seed)
            for invalid in ["12x", "--5", "0xzz"] {
                assertInvalidValue(try parse(invalid), key: invalid, hiding: nil)
            }
        }
    }

    func testTxRepAssetParsersNeverStoreASeed() {
        let parsers: [(String) throws -> Void] = [
            { _ = try TxRepHelper.parseAsset($0) },
            { _ = try TxRepHelper.parseChangeTrustAsset($0) },
            { _ = try TxRepHelper.parseTrustlineAsset($0) },
        ]
        let longCode = "SUPERLONGCODE:\(accountG)"
        for parse in parsers {
            for variant in variants.all {
                assertInvalidValue(try parse(variant), key: seedText, hiding: variant)
                assertInvalidValue(try parse("\(variant):\(accountG)"), key: "\(seedText):\(accountG)", hiding: variant)
            }
            assertInvalidValue(try parse("USDC"), key: "USDC", hiding: nil)
            assertInvalidValue(try parse(longCode), key: longCode, hiding: nil)
        }
        for variant in variants.all {
            let spaces = String(repeating: " ", count: 64 - variant.count)
            assertInvalidValue(try TxRepHelper.parseTrustlineAsset(spaces + variant), key: spaces + seedText, hiding: variant)
            assertInvalidValue(try TxRepHelper.parseAllowTrustAsset(variant), key: seedText, hiding: variant)
        }
        let notHex = String(repeating: "z", count: 64)
        assertInvalidValue(try TxRepHelper.parseTrustlineAsset(notHex), key: notHex, hiding: nil)
        assertInvalidValue(try TxRepHelper.parseAllowTrustAsset("SUPERLONGCODE"), key: "SUPERLONGCODE", hiding: nil)
    }

    func testTxRepStringUnescapingNeverStoresASeed() {
        for variant in variants.all {
            assertInvalidValue(try TxRepHelper.unescapeString("\"\(variant)\\xff\""), key: "\"\(seedText)\\xff\"", hiding: variant)
            assertInvalidValue(try TxRepHelper.unescapeBytes("\"\(variant)"), key: "\"\(seedText)", hiding: variant)
            assertInvalidValue(try TxRepHelper.unescapeBytes("\"\(variant)\\xzz\""), key: "\"\(seedText)\\xzz\"", hiding: variant)
        }
        for invalid in ["\"abc\\xff\"", "\"abc", "\"abc\\xzz\""] {
            assertInvalidValue(try TxRepHelper.unescapeString(invalid), key: invalid, hiding: nil)
        }
    }

    func testUnknownMethodNeverShowsASeed() async throws {
        let options = ClientOptions(sourceAccountKeyPair: try KeyPair.generateRandomKeyPair(),
                                    contractId: "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE",
                                    network: .testnet, rpcUrl: "http://127.0.0.1:9")
        let client = SorobanClient(specEntries: [], clientOptions: options)
        let names = variants.all.map { ($0, seedText) } + [("x" + variants.seed, "x" + seedText), ("nonexistent", "nonexistent")]
        for (name, shown) in names {
            do {
                _ = try await client.buildInvokeMethodTx(name: name)
                XCTFail("expected methodNotFound")
            } catch SorobanClientError.methodNotFound(let message) {
                XCTAssertEqual(message, "Method '\(shown)' does not exist.")
            } catch {
                XCTFail("expected methodNotFound, got \(type(of: error))")
            }
        }
    }

    func testUnknownSpecNamesNeverStoreASeed() {
        let spec = ContractSpec(entries: [])
        let names = variants.all.map { ($0, seedText) } + [("x" + variants.seed, "x" + seedText), ("hello", "hello")]
        for (name, stored) in names {
            XCTAssertThrowsError(try spec.funcArgsToXdrSCValues(name: name, args: [:])) { error in
                guard case ContractSpecError.functionNotFound(let storedName) = error else {
                    return XCTFail("expected functionNotFound, got \(type(of: error))")
                }
                XCTAssertEqual(storedName, stored)
                XCTAssertEqual(String(describing: error).contains(name), name == stored)
            }
            XCTAssertThrowsError(try spec.nativeToXdrSCVal(val: 1, ty: .udt(SCSpecTypeUDTXDR(name: name)))) { error in
                guard case ContractSpecError.entryNotFound(let storedName) = error else {
                    return XCTFail("expected entryNotFound, got \(type(of: error))")
                }
                XCTAssertEqual(storedName, stored)
                XCTAssertEqual(String(describing: error).contains(name), name == stored)
            }
        }
    }

    func testDuplicateMapKeyNeverShowsASeed() throws {
        let keys = variants.all + ["x" + variants.seed]
        for key in keys {
            for scKey in [SCValXDR.string(key), SCValXDR.symbol(key)] {
                // The text the error names a key by: its XDR-JSON, or its description where the
                // key has none (a symbol longer than the 32 characters XDR allows).
                let json = (try? scKey.toXdrJson()) ?? String(describing: scKey)
                let entries = [SCMapEntryXDR(key: scKey, val: .u32(1)), SCMapEntryXDR(key: scKey, val: .u32(2))]
                let shown = key.hasPrefix("x") ? "x" + seedText : seedText
                assertInvalidArgument(try SCValXDR.sortedMap(entries),
                                      "Duplicate ScMap key: " + json.replacingOccurrences(of: key, with: shown))
            }
        }
        let plain = SCValXDR.string("abc")
        assertInvalidArgument(try SCValXDR.sortedMap([SCMapEntryXDR(key: plain, val: .u32(1)),
                                                      SCMapEntryXDR(key: plain, val: .u32(2))]),
                              "Duplicate ScMap key: \(try plain.toXdrJson())")
    }

    // MARK: - Helpers

    private func assertInvalidArgument<T>(_ expression: @autoclosure () throws -> T, _ expected: String,
                                          file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            guard case StellarSDKError.invalidArgument(let message) = error else {
                return XCTFail("Expected invalidArgument, got \(error)", file: file, line: line)
            }
            XCTAssertEqual(message, expected, file: file, line: line)
        }
    }

    private func assertInvalidType(_ value: Any, _ ty: SCSpecTypeDefXDR, _ expected: String,
                                   file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try ContractSpec(entries: []).nativeToXdrSCVal(val: value, ty: ty), file: file, line: line) { error in
            guard case ContractSpecError.invalidType(let message) = error else {
                return XCTFail("Expected invalidType, got \(error)", file: file, line: line)
            }
            XCTAssertEqual(message, expected, file: file, line: line)
        }
    }

    private func assertInvalidEnumValue<T>(_ expression: @autoclosure () throws -> T, _ expected: String,
                                           file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            guard case ContractSpecError.invalidEnumValue(let message) = error else {
                return XCTFail("Expected invalidEnumValue, got \(error)", file: file, line: line)
            }
            XCTAssertEqual(message, expected, file: file, line: line)
        }
    }

    /// Asserts a `TxRepError.invalidValue` storing `key`, whose description does not hold
    /// `hidden`.
    private func assertInvalidValue<T>(_ expression: @autoclosure () throws -> T, key expected: String, hiding hidden: String?,
                                       file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            guard case TxRepError.invalidValue(let key) = error else {
                return XCTFail("Expected TxRepError.invalidValue, got \(error)", file: file, line: line)
            }
            XCTAssertEqual(key, expected, file: file, line: line)
            if let hidden = hidden {
                XCTAssertFalse(String(describing: error).contains(hidden), file: file, line: line)
            }
        }
    }
}
