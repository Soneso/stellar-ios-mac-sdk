//
//  AssetTestCase.swift
//  stellarsdk
//
//  Created by Claude on 03.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class AssetTestCase: XCTestCase {

    // Test issuer keypair for all tests
    let testIssuerSeed = "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN"
    let testIssuerAccountId = "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6"
    var testIssuer: KeyPair!

    // Second issuer for testing equality
    let testIssuer2Seed = "SAEWIVK3VLNEJ3WEJRZXQGDAS5NVG2BYSYDFRSH4GKVTS5RXNVED5AX7"
    let testIssuer2AccountId = "GC3MMSXBWHL6CPOAVERSJITX7BH76YU252WGLUOM5CJX3E7UCYZBTPJQ"
    var testIssuer2: KeyPair!

    override func setUp() {
        super.setUp()
        testIssuer = try! KeyPair(secretSeed: testIssuerSeed)
        testIssuer2 = try! KeyPair(secretSeed: testIssuer2Seed)
    }

    override func tearDown() {
        testIssuer = nil
        testIssuer2 = nil
        super.tearDown()
    }

    // MARK: - Test 1: Native Asset

    func testAssetNative() {
        // Create native asset (XLM)
        let asset = Asset(type: AssetType.ASSET_TYPE_NATIVE)

        XCTAssertNotNil(asset)
        guard let nativeAsset = asset else {
            XCTFail("Failed to create native asset")
            return
        }

        // Verify type
        XCTAssertEqual(nativeAsset.type, AssetType.ASSET_TYPE_NATIVE)

        // Verify code and issuer are nil for native asset
        XCTAssertNil(nativeAsset.code)
        XCTAssertNil(nativeAsset.issuer)
    }

    // MARK: - Test 2: AlphaNum4 Asset

    func testAssetAlphanum4() {
        // Test with 1-character code
        var asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "X", issuer: testIssuer)
        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.code, "X")
        XCTAssertEqual(asset?.type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
        XCTAssertEqual(asset?.issuer?.accountId, testIssuerAccountId)

        // Test with 4-character code
        asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: testIssuer)
        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.code, "USD")
        XCTAssertEqual(asset?.type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)

        // Test with exactly 4 characters
        asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "ABCD", issuer: testIssuer)
        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.code, "ABCD")

        // Test that 5+ character code fails for AlphaNum4
        asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "ABCDE", issuer: testIssuer)
        XCTAssertNil(asset)
    }

    // MARK: - Test 3: AlphaNum12 Asset

    func testAssetAlphanum12() {
        // Test with 5-character code (minimum for AlphaNum12)
        var asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "ABCDE", issuer: testIssuer)
        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.code, "ABCDE")
        XCTAssertEqual(asset?.type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM12)
        XCTAssertEqual(asset?.issuer?.accountId, testIssuerAccountId)

        // Test with 12-character code (maximum)
        asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "ABCDEFGHIJKL", issuer: testIssuer)
        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.code, "ABCDEFGHIJKL")

        // Test that 4 or less character code fails for AlphaNum12
        asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "ABCD", issuer: testIssuer)
        XCTAssertNil(asset)

        // Test that 13+ character code fails
        asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "ABCDEFGHIJKLM", issuer: testIssuer)
        XCTAssertNil(asset)
    }

    // MARK: - Test 4: Asset from Canonical Form

    func testAssetFromCanonicalForm() {
        // Test native asset from "native"
        var asset = Asset(canonicalForm: "native")
        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.type, AssetType.ASSET_TYPE_NATIVE)

        // Test native asset from "XLM"
        asset = Asset(canonicalForm: "XLM")
        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.type, AssetType.ASSET_TYPE_NATIVE)

        // Test AlphaNum4 from "CODE:ISSUER"
        let canonical4 = "USD:\(testIssuerAccountId)"
        asset = Asset(canonicalForm: canonical4)
        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
        XCTAssertEqual(asset?.code, "USD")
        XCTAssertEqual(asset?.issuer?.accountId, testIssuerAccountId)

        // Test AlphaNum12 from "CODE:ISSUER"
        let canonical12 = "ABCDEFGH:\(testIssuerAccountId)"
        asset = Asset(canonicalForm: canonical12)
        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM12)
        XCTAssertEqual(asset?.code, "ABCDEFGH")
        XCTAssertEqual(asset?.issuer?.accountId, testIssuerAccountId)

        // Test with whitespace
        asset = Asset(canonicalForm: " BTC : \(testIssuerAccountId) ")
        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.code, "BTC")
        XCTAssertEqual(asset?.issuer?.accountId, testIssuerAccountId)

        // Test invalid formats
        asset = Asset(canonicalForm: "InvalidFormat")
        XCTAssertNil(asset)

        asset = Asset(canonicalForm: "USD")
        XCTAssertNil(asset)

        asset = Asset(canonicalForm: "USD:INVALID_ACCOUNT_ID")
        XCTAssertNil(asset)

        asset = Asset(canonicalForm: "USD:ISSUER:EXTRA")
        XCTAssertNil(asset)
    }

    // MARK: - Test 5: Asset to Canonical Form

    func testAssetToCanonicalForm() {
        // Test native asset
        let nativeAsset = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        XCTAssertEqual(nativeAsset.toCanonicalForm(), "native")

        // Test AlphaNum4 asset
        let asset4 = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: testIssuer)!
        let expected4 = "USD:\(testIssuerAccountId)"
        XCTAssertEqual(asset4.toCanonicalForm(), expected4)

        // Test AlphaNum12 asset
        let asset12 = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "ABCDEFGH", issuer: testIssuer)!
        let expected12 = "ABCDEFGH:\(testIssuerAccountId)"
        XCTAssertEqual(asset12.toCanonicalForm(), expected12)
    }

    // MARK: - Test 6: Asset Equality

    func testAssetEquality() {
        // Create same assets
        let asset1 = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: testIssuer)!
        let asset2 = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: testIssuer)!

        // Verify they produce the same canonical form
        XCTAssertEqual(asset1.toCanonicalForm(), asset2.toCanonicalForm())

        // Create different assets
        let asset3 = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "EUR", issuer: testIssuer)!
        XCTAssertNotEqual(asset1.toCanonicalForm(), asset3.toCanonicalForm())

        let asset4 = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: testIssuer2)!
        XCTAssertNotEqual(asset1.toCanonicalForm(), asset4.toCanonicalForm())

        // Native assets
        let native1 = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let native2 = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        XCTAssertEqual(native1.toCanonicalForm(), native2.toCanonicalForm())
    }

    // MARK: - Test 7: Asset Code Too Long Throws

    func testAssetCodeTooLongThrows() {
        // Test code longer than 12 characters fails for AlphaNum12
        let asset12 = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "ABCDEFGHIJKLM", issuer: testIssuer)
        XCTAssertNil(asset12)

        let asset12Long = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "VERYLONGASSETCODE", issuer: testIssuer)
        XCTAssertNil(asset12Long)

        // Test code longer than 4 characters fails for AlphaNum4
        let asset4 = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "ABCDE", issuer: testIssuer)
        XCTAssertNil(asset4)
    }

    // MARK: - Test 8: Invalid Issuer Throws

    func testAssetInvalidIssuerThrows() {
        // Test AlphaNum4 without issuer
        var asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: nil)
        XCTAssertNil(asset)

        // Test AlphaNum12 without issuer
        asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "ABCDEFGH", issuer: nil)
        XCTAssertNil(asset)

        // Test empty code
        asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "", issuer: testIssuer)
        XCTAssertNil(asset)

        asset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "", issuer: testIssuer)
        XCTAssertNil(asset)
    }

    // MARK: - Test 9: Pool Share Asset

    func testAssetPoolShare() throws {
        // Create two assets for the pool
        let assetA = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let assetB = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: testIssuer)!

        // Create pool share asset
        let poolAsset = try ChangeTrustAsset(assetA: assetA, assetB: assetB)

        XCTAssertNotNil(poolAsset)
        guard let pool = poolAsset else {
            XCTFail("Failed to create pool share asset")
            return
        }

        XCTAssertEqual(pool.type, AssetType.ASSET_TYPE_POOL_SHARE)
        XCTAssertEqual(pool.assetA?.type, AssetType.ASSET_TYPE_NATIVE)
        XCTAssertEqual(pool.assetB?.code, "USD")

        // Test canonical form for pool share
        let canonical = pool.toCanonicalForm()
        XCTAssertTrue(canonical.hasSuffix(":lp"))

        // Test wrong order (should throw)
        XCTAssertThrowsError(try ChangeTrustAsset(assetA: assetB, assetB: assetA)) { error in
            if case StellarSDKError.invalidArgument(let message) = error {
                XCTAssertTrue(message.contains("wrong order"))
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Test two native assets (should throw)
        XCTAssertThrowsError(try ChangeTrustAsset(assetA: assetA, assetB: assetA)) { error in
            if case StellarSDKError.invalidArgument(let message) = error {
                XCTAssertTrue(message.contains("native") || message.contains("NATIVE"))
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Test 10: XDR Roundtrip

    func testAssetXDRRoundtrip() throws {
        // Test native asset XDR roundtrip
        let nativeAsset = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let nativeXDR = try nativeAsset.toXDR()
        let nativeRestored = try Asset.fromXDR(assetXDR: nativeXDR)

        XCTAssertEqual(nativeRestored.type, AssetType.ASSET_TYPE_NATIVE)
        XCTAssertNil(nativeRestored.code)
        XCTAssertNil(nativeRestored.issuer)

        // Test AlphaNum4 asset XDR roundtrip
        let asset4 = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: testIssuer)!
        let xdr4 = try asset4.toXDR()
        let restored4 = try Asset.fromXDR(assetXDR: xdr4)

        XCTAssertEqual(restored4.type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
        XCTAssertEqual(restored4.code, "USD")
        XCTAssertEqual(restored4.issuer?.accountId, testIssuerAccountId)
        XCTAssertEqual(asset4.toCanonicalForm(), restored4.toCanonicalForm())

        // Test AlphaNum12 asset XDR roundtrip
        let asset12 = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "ABCDEFGH", issuer: testIssuer)!
        let xdr12 = try asset12.toXDR()
        let restored12 = try Asset.fromXDR(assetXDR: xdr12)

        XCTAssertEqual(restored12.type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM12)
        XCTAssertEqual(restored12.code, "ABCDEFGH")
        XCTAssertEqual(restored12.issuer?.accountId, testIssuerAccountId)
        XCTAssertEqual(asset12.toCanonicalForm(), restored12.toCanonicalForm())

        // Test with different code lengths
        let shortCode = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "X", issuer: testIssuer)!
        let shortXDR = try shortCode.toXDR()
        let restoredShort = try Asset.fromXDR(assetXDR: shortXDR)
        XCTAssertEqual(restoredShort.code, "X")

        let longCode = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "ABCDEFGHIJKL", issuer: testIssuer)!
        let longXDR = try longCode.toXDR()
        let restoredLong = try Asset.fromXDR(assetXDR: longXDR)
        XCTAssertEqual(restoredLong.code, "ABCDEFGHIJKL")
    }

    // MARK: - Additional Tests

    func testAssetInvalidType() {
        // Test with invalid type value
        let asset = Asset(type: 99, code: "USD", issuer: testIssuer)
        XCTAssertNil(asset)
    }

    func testAssetCodeBoundaries() {
        // Test minimum code length
        let minAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "A", issuer: testIssuer)
        XCTAssertNotNil(minAsset)
        XCTAssertEqual(minAsset?.code, "A")

        // Test boundary between AlphaNum4 and AlphaNum12
        let fourChar = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "ABCD", issuer: testIssuer)
        XCTAssertNotNil(fourChar)

        let fiveChar = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "ABCDE", issuer: testIssuer)
        XCTAssertNotNil(fiveChar)

        // Test maximum AlphaNum12 code length
        let maxAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "ABCDEFGHIJKL", issuer: testIssuer)
        XCTAssertNotNil(maxAsset)
        XCTAssertEqual(maxAsset?.code, "ABCDEFGHIJKL")
    }

    func testAssetNativeIgnoresParameters() {
        // Native asset should ignore code and issuer
        let nativeAsset = Asset(type: AssetType.ASSET_TYPE_NATIVE, code: "USD", issuer: testIssuer)
        XCTAssertNotNil(nativeAsset)
        XCTAssertEqual(nativeAsset?.type, AssetType.ASSET_TYPE_NATIVE)
        XCTAssertNil(nativeAsset?.code)
        XCTAssertNil(nativeAsset?.issuer)
    }

    func testAssetCanonicalFormRoundtrip() {
        // Test that converting to canonical form and back produces equivalent asset
        let originalAsset = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "BTC", issuer: testIssuer)!
        let canonical = originalAsset.toCanonicalForm()
        let restoredAsset = Asset(canonicalForm: canonical)

        XCTAssertNotNil(restoredAsset)
        XCTAssertEqual(originalAsset.type, restoredAsset?.type)
        XCTAssertEqual(originalAsset.code, restoredAsset?.code)
        XCTAssertEqual(originalAsset.issuer?.accountId, restoredAsset?.issuer?.accountId)
        XCTAssertEqual(originalAsset.toCanonicalForm(), restoredAsset?.toCanonicalForm())
    }

    func testChangeTrustAssetXDRRoundtrip() throws {
        // Test ChangeTrustAsset XDR roundtrip for pool share
        let assetA = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let assetB = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: testIssuer)!

        let poolAsset = try ChangeTrustAsset(assetA: assetA, assetB: assetB)
        XCTAssertNotNil(poolAsset)
        let xdr = try poolAsset!.toChangeTrustAssetXDR()
        let restored = try ChangeTrustAsset.fromXDR(assetXDR: xdr)

        XCTAssertEqual(restored.type, AssetType.ASSET_TYPE_POOL_SHARE)
        XCTAssertEqual(restored.assetA?.type, AssetType.ASSET_TYPE_NATIVE)
        XCTAssertEqual(restored.assetB?.code, "USD")
        XCTAssertEqual(restored.assetB?.issuer?.accountId, testIssuerAccountId)

        // Test regular asset as ChangeTrustAsset
        let regularAsset = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "EUR", issuer: testIssuer)!
        let regularXDR = try regularAsset.toChangeTrustAssetXDR()
        let restoredRegular = try ChangeTrustAsset.fromXDR(assetXDR: regularXDR)

        XCTAssertEqual(restoredRegular.type, AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
        XCTAssertEqual(restoredRegular.code, "EUR")
        XCTAssertEqual(restoredRegular.issuer?.accountId, testIssuerAccountId)
    }
}
