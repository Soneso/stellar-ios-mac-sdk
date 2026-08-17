//
//  HexIdBoundaryUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Pins the boundary where the hexadecimal spelling of a 32 byte id enters and leaves the SDK:
/// the width every factory that takes a hex id demands, and the spelling SCAddressXDR reports a
/// claimable balance id in.
class HexIdBoundaryUnitTests: XCTestCase {

    /// The 64 hexadecimal characters a 32 byte id is wide.
    private let validHex = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"

    /// Four bytes, not thirty two.
    private let shortHex = "deadbeef"

    /// Forty bytes, not thirty two.
    private var longHex: String { return validHex + String(validHex.prefix(16)) }

    /// The id behind a leading pair that belongs to no id: 33 bytes, not thirty two.
    private var paddedHex: String { return "00" + validHex }

    /// The right width, with a pair in the middle outside the hexadecimal alphabet.
    private var nonHex: String { return String(validHex.prefix(30)) + "zz" + String(validHex.suffix(32)) }

    /// The right width, but two of the characters are a "0x" prefix, so it spells 31 bytes.
    private var prefixedHex: String { return "0x" + String(validHex.dropFirst(2)) }

    /// The right width, every pair signed: UInt8(_:radix:) reads "+1" as a byte.
    private var signedPairsHex: String { return String(repeating: "+1", count: 32) }

    /// A 64 character hex id, spelled uppercase, leading with the hexadecimal digit "C".
    private var upperCaseCHex: String { return "C" + String(validHex.dropFirst()).uppercased() }

    /// Every spelling that names no 32 byte id, with the character count it carries.
    private var wrongWidths: [(id: String, count: Int)] {
        return [(shortHex, 8), (longHex, 80), (paddedHex, 66)]
    }

    /// A claimable balance id as its "B..." strkey and as the bare 32 byte hash.
    private let claimableBalanceStrKey = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU"
    private let claimableBalanceHash = "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"

    /// That same id in the form Horizon serves: the four byte union discriminant ahead of the hash.
    private var horizonBalanceId: String { return "00000000" + claimableBalanceHash }

    private let accountId = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
    private let price = PriceXDR(n: 1, d: 2)

    // MARK: - Fixtures

    /// The gates under test read widths, so a fixture of the wrong width would make every
    /// assertion below vacuous.
    func testFixtureWidths() {
        XCTAssertEqual(64, validHex.count)
        XCTAssertEqual(8, shortHex.count)
        XCTAssertEqual(80, longHex.count)
        XCTAssertEqual(66, paddedHex.count)
        XCTAssertEqual(64, nonHex.count)
        XCTAssertEqual(64, prefixedHex.count)
        XCTAssertEqual(64, signedPairsHex.count)
        XCTAssertEqual(64, upperCaseCHex.count)
        XCTAssertEqual(64, claimableBalanceHash.count)
        XCTAssertEqual(72, horizonBalanceId.count)
    }

    // MARK: - SCAddressXDR(contractId:)

    func testContractAddressTakesTheExactWidth() throws {
        XCTAssertEqual(validHex, try SCAddressXDR(contractId: validHex).contractId)
    }

    func testContractAddressTakesTheStrkey() throws {
        let strKey = try validHex.encodeContractIdHex()
        XCTAssertEqual(validHex, try SCAddressXDR(contractId: strKey).contractId)
    }

    func testContractAddressRefusesOtherWidths() {
        for wrong in wrongWidths {
            XCTAssertEqual(lengthMessage("contract id", wrong.count),
                           invalidArgumentMessage { try SCAddressXDR(contractId: wrong.id) })
        }
    }

    func testContractAddressRefusesNonHex() {
        XCTAssertEqual(alphabetMessage("contract id", nonHex),
                       invalidArgumentMessage { try SCAddressXDR(contractId: nonHex) })
    }

    /// A "0x" prefix passes the character count while spelling one byte less than an id.
    func testContractAddressRefusesPrefixedHex() {
        XCTAssertEqual(alphabetMessage("contract id", prefixedHex),
                       invalidArgumentMessage { try SCAddressXDR(contractId: prefixedHex) })
    }

    /// Signed pairs pass the character count and the pair parser both.
    func testContractAddressRefusesSignedPairs() {
        XCTAssertEqual(alphabetMessage("contract id", signedPairsHex),
                       invalidArgumentMessage { try SCAddressXDR(contractId: signedPairsHex) })
    }

    /// "C" is a hexadecimal digit, so an uppercase hex id may lead with it; only the
    /// 56 character strkey length reads as a strkey.
    func testContractAddressTakesUppercaseHexLeadingWithC() throws {
        XCTAssertEqual(upperCaseCHex.lowercased(),
                       try SCAddressXDR(contractId: upperCaseCHex).contractId)
    }

    // MARK: - SCAddressXDR(liquidityPoolId:)

    func testLiquidityPoolAddressTakesTheExactWidth() throws {
        XCTAssertEqual(validHex, try SCAddressXDR(liquidityPoolId: validHex).liquidityPoolId)
    }

    func testLiquidityPoolAddressTakesTheStrkey() throws {
        let strKey = try validHex.encodeLiquidityPoolIdHex()
        XCTAssertEqual(validHex, try SCAddressXDR(liquidityPoolId: strKey).liquidityPoolId)
    }

    func testLiquidityPoolAddressRefusesOtherWidths() {
        for wrong in wrongWidths {
            XCTAssertEqual(lengthMessage("liquidity pool id", wrong.count),
                           invalidArgumentMessage { try SCAddressXDR(liquidityPoolId: wrong.id) })
        }
    }

    func testLiquidityPoolAddressRefusesNonHex() {
        XCTAssertEqual(alphabetMessage("liquidity pool id", nonHex),
                       invalidArgumentMessage { try SCAddressXDR(liquidityPoolId: nonHex) })
    }

    // MARK: - LiquidityPoolDepositOpXDR(liquidityPoolId:)

    func testDepositOpTakesTheExactWidth() throws {
        let op = try LiquidityPoolDepositOpXDR(liquidityPoolId: validHex, maxAmountA: 100,
                                               maxAmountB: 200, minPrice: price, maxPrice: price)
        XCTAssertEqual(validHex, op.liquidityPoolID.wrapped.base16EncodedString())
    }

    func testDepositOpRefusesOtherWidths() {
        for wrong in wrongWidths {
            XCTAssertEqual(lengthMessage("liquidity pool id", wrong.count),
                           invalidArgumentMessage {
                               try LiquidityPoolDepositOpXDR(liquidityPoolId: wrong.id, maxAmountA: 100,
                                                             maxAmountB: 200, minPrice: price, maxPrice: price)
                           })
        }
    }

    func testDepositOpRefusesNonHex() {
        XCTAssertEqual(alphabetMessage("liquidity pool id", nonHex),
                       invalidArgumentMessage {
                           try LiquidityPoolDepositOpXDR(liquidityPoolId: nonHex, maxAmountA: 100,
                                                         maxAmountB: 200, minPrice: price, maxPrice: price)
                       })
    }

    // MARK: - LiquidityPoolWithdrawOpXDR(liquidityPoolId:)

    func testWithdrawOpTakesTheExactWidth() throws {
        let op = try LiquidityPoolWithdrawOpXDR(liquidityPoolId: validHex, amount: 100,
                                                minAmountA: 10, minAmountB: 20)
        XCTAssertEqual(validHex, op.liquidityPoolID.wrapped.base16EncodedString())
    }

    func testWithdrawOpRefusesOtherWidths() {
        for wrong in wrongWidths {
            XCTAssertEqual(lengthMessage("liquidity pool id", wrong.count),
                           invalidArgumentMessage {
                               try LiquidityPoolWithdrawOpXDR(liquidityPoolId: wrong.id, amount: 100,
                                                              minAmountA: 10, minAmountB: 20)
                           })
        }
    }

    func testWithdrawOpRefusesNonHex() {
        XCTAssertEqual(alphabetMessage("liquidity pool id", nonHex),
                       invalidArgumentMessage {
                           try LiquidityPoolWithdrawOpXDR(liquidityPoolId: nonHex, amount: 100,
                                                          minAmountA: 10, minAmountB: 20)
                       })
    }

    // MARK: - TrustlineAssetXDR(poolId:)

    func testPoolShareTrustlineTakesTheExactWidth() throws {
        XCTAssertEqual(validHex, try TrustlineAssetXDR(poolId: validHex).poolId)
    }

    /// The 66 character case matters on its own: a leading "00" pair belongs to no pool id.
    func testPoolShareTrustlineRefusesOtherWidths() {
        for wrong in wrongWidths {
            XCTAssertEqual(lengthMessage("liquidity pool id", wrong.count),
                           invalidArgumentMessage { try TrustlineAssetXDR(poolId: wrong.id) })
        }
    }

    func testPoolShareTrustlineRefusesNonHex() {
        XCTAssertEqual(alphabetMessage("liquidity pool id", nonHex),
                       invalidArgumentMessage { try TrustlineAssetXDR(poolId: nonHex) })
    }

    // MARK: - LedgerKeyContractCodeXDR(wasmId:)

    func testContractCodeKeyTakesTheExactWidth() throws {
        let key = try LedgerKeyContractCodeXDR(wasmId: validHex)
        XCTAssertEqual(validHex, key.hash.wrapped.base16EncodedString())
    }

    func testContractCodeKeyRefusesOtherWidths() {
        for wrong in wrongWidths {
            XCTAssertEqual(lengthMessage("wasm id", wrong.count),
                           invalidArgumentMessage { try LedgerKeyContractCodeXDR(wasmId: wrong.id) })
        }
    }

    func testContractCodeKeyRefusesNonHex() {
        XCTAssertEqual(alphabetMessage("wasm id", nonHex),
                       invalidArgumentMessage { try LedgerKeyContractCodeXDR(wasmId: nonHex) })
    }

    // MARK: - InvokeHostFunctionOperation wasm id

    func testCreateContractTakesTheExactWidth() throws {
        let op = try InvokeHostFunctionOperation.forCreatingContract(wasmId: validHex,
                                                                    address: try SCAddressXDR(accountId: accountId))
        XCTAssertEqual(validHex, wasmHash(of: op))
    }

    func testCreateContractRefusesOtherWidths() throws {
        let address = try SCAddressXDR(accountId: accountId)
        for wrong in wrongWidths {
            XCTAssertEqual(lengthMessage("wasm id", wrong.count),
                           invalidArgumentMessage {
                               try InvokeHostFunctionOperation.forCreatingContract(wasmId: wrong.id, address: address)
                           })
        }
    }

    func testCreateContractRefusesNonHex() throws {
        let address = try SCAddressXDR(accountId: accountId)
        XCTAssertEqual(alphabetMessage("wasm id", nonHex),
                       invalidArgumentMessage {
                           try InvokeHostFunctionOperation.forCreatingContract(wasmId: nonHex, address: address)
                       })
    }

    func testCreateContractWithConstructorTakesTheExactWidth() throws {
        let op = try InvokeHostFunctionOperation.forCreatingContractWithConstructor(
            wasmId: validHex,
            address: try SCAddressXDR(accountId: accountId),
            constructorArguments: [SCValXDR.u32(1)])
        XCTAssertEqual(validHex, wasmHash(of: op))
    }

    func testCreateContractWithConstructorRefusesOtherWidths() throws {
        let address = try SCAddressXDR(accountId: accountId)
        for wrong in wrongWidths {
            XCTAssertEqual(lengthMessage("wasm id", wrong.count),
                           invalidArgumentMessage {
                               try InvokeHostFunctionOperation.forCreatingContractWithConstructor(wasmId: wrong.id,
                                                                                                 address: address)
                           })
        }
    }

    func testCreateContractWithConstructorRefusesNonHex() throws {
        let address = try SCAddressXDR(accountId: accountId)
        XCTAssertEqual(alphabetMessage("wasm id", nonHex),
                       invalidArgumentMessage {
                           try InvokeHostFunctionOperation.forCreatingContractWithConstructor(wasmId: nonHex,
                                                                                              address: address)
                       })
    }

    // MARK: - Claimable balance id spelling

    func testClaimableBalanceAddressReportsTheHorizonForm() throws {
        let address = try SCAddressXDR(claimableBalanceId: claimableBalanceStrKey)
        XCTAssertEqual(horizonBalanceId, address.claimableBalanceId)
        XCTAssertEqual(claimableBalanceStrKey, try address.getClaimableBalanceIdStrKey())
    }

    /// However the id is spelled going in, one spelling comes back out.
    func testEverySpellingReportsTheHorizonForm() throws {
        for spelling in [claimableBalanceStrKey, claimableBalanceHash, "00" + claimableBalanceHash, horizonBalanceId] {
            let address = try SCAddressXDR(claimableBalanceId: spelling)
            XCTAssertEqual(horizonBalanceId, address.claimableBalanceId)
            XCTAssertEqual(claimableBalanceStrKey, try address.getClaimableBalanceIdStrKey())
        }
    }

    // MARK: - Helpers

    private func lengthMessage(_ idKind: String, _ given: Int) -> String {
        return "invalid \(idKind) length \(given), must be 64 hex characters"
    }

    private func alphabetMessage(_ idKind: String, _ given: String) -> String {
        return "invalid \(idKind), not a hex string \(given)"
    }

    /// The message of the StellarSDKError.invalidArgument `build` throws. Fails the test if
    /// `build` throws anything else, or nothing at all.
    private func invalidArgumentMessage(file: StaticString = #filePath,
                                        line: UInt = #line,
                                        _ build: () throws -> Any) -> String {
        do {
            _ = try build()
            XCTFail("expected StellarSDKError.invalidArgument, nothing was thrown", file: file, line: line)
        } catch StellarSDKError.invalidArgument(let message) {
            return message
        } catch {
            XCTFail("expected StellarSDKError.invalidArgument, got \(error)", file: file, line: line)
        }
        return ""
    }

    private func wasmHash(of operation: InvokeHostFunctionOperation) -> String? {
        switch operation.hostFunction {
        case .createContract(let args):
            guard case .wasm(let hash) = args.executable else { return nil }
            return hash.wrapped.base16EncodedString()
        case .createContractV2(let args):
            guard case .wasm(let hash) = args.executable else { return nil }
            return hash.wrapped.base16EncodedString()
        default:
            return nil
        }
    }
}
