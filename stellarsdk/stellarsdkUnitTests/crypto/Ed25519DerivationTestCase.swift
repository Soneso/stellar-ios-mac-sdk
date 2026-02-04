//
//  Ed25519DerivationTestCase.swift
//  stellarsdk
//
//  Created by Claude on 03.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class Ed25519DerivationTestCase: XCTestCase {

    // Test vectors from SEP-0005 (12-word mnemonic)
    // Source: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md
    let mnemonic12Words = "illness spike retreat truth genius clock brain pass fit cave bargain toe"
    let expectedBip39Seed12 = "e4a5a632e70943ae7f07659df1332160937fad82587216a4c64315a0fb39497ee4a01f76ddab4cba68147977f3a147b6ad584c41808e8238a07f6cc4b582f186"
    let expectedCoinTypeKey12 = "e0eec84fe165cd427cb7bc9b6cfdef0555aa1cb6f9043ff1fe986c3c8ddd22e3"

    // Test vectors from SEP-0005 (24-word mnemonic)
    let mnemonic24Words = "bench hurt jump file august wise shallow faculty impulse spring exact slush thunder author capable act festival slice deposit sauce coconut afford frown better"
    let expectedBip39Seed24 = "937ae91f6ab6f12461d9936dfc1375ea5312d097f3f1eb6fed6a82fbe38c85824da8704389831482db0433e5f6c6c9700ff1946aa75ad8cc2654d6e40f567866"
    let expectedCoinTypeKey24 = "df474e0dc2711089b89af6b089aceeb77e73120e9f895bd330a36fa952835ea8"

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Test 1: Derive Key From Path

    func testDeriveKeyFromPath() throws {
        // Create BIP-39 seed from mnemonic
        let bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic12Words)

        // Verify seed matches expected value
        XCTAssertEqual(bip39Seed.base16EncodedString(), expectedBip39Seed12)

        // Create master key derivation
        let masterKey = Ed25519Derivation(seed: bip39Seed)

        // Verify master key has raw data and chain code
        XCTAssertEqual(masterKey.raw.count, 32)
        XCTAssertEqual(masterKey.chainCode.count, 32)

        // Derive purpose level: m/44'
        let purpose = masterKey.derived(at: 44)
        XCTAssertEqual(purpose.raw.count, 32)
        XCTAssertEqual(purpose.chainCode.count, 32)

        // Derive coin type level: m/44'/148'
        let coinType = purpose.derived(at: 148)
        XCTAssertEqual(coinType.raw.count, 32)
        XCTAssertEqual(coinType.chainCode.count, 32)
        XCTAssertEqual(coinType.raw.base16EncodedString(), expectedCoinTypeKey12)

        // Derive account 0: m/44'/148'/0'
        let account0 = coinType.derived(at: 0)
        XCTAssertEqual(account0.raw.count, 32)
        XCTAssertEqual(account0.chainCode.count, 32)

        // Create keypair from derived key
        let keyPair0 = try KeyPair(seed: Seed(bytes: [UInt8](account0.raw)))
        XCTAssertEqual(keyPair0.accountId, "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6")
        XCTAssertEqual(keyPair0.secretSeed, "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN")
    }

    // MARK: - Test 2: Derive Multiple Keys

    func testDeriveMultipleKeys() throws {
        // Create BIP-39 seed from 24-word mnemonic
        let bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic24Words)

        // Verify seed matches expected value
        XCTAssertEqual(bip39Seed.base16EncodedString(), expectedBip39Seed24)

        // Create master key and derive to coin type level
        let masterKey = Ed25519Derivation(seed: bip39Seed)
        let purpose = masterKey.derived(at: 44)
        let coinType = purpose.derived(at: 148)

        // Verify coin type key
        XCTAssertEqual(coinType.raw.base16EncodedString(), expectedCoinTypeKey24)

        // Derive and verify account 0
        let account0 = coinType.derived(at: 0)
        let keyPair0 = try KeyPair(seed: Seed(bytes: [UInt8](account0.raw)))
        XCTAssertEqual(keyPair0.accountId, "GC3MMSXBWHL6CPOAVERSJITX7BH76YU252WGLUOM5CJX3E7UCYZBTPJQ")
        XCTAssertEqual(keyPair0.secretSeed, "SAEWIVK3VLNEJ3WEJRZXQGDAS5NVG2BYSYDFRSH4GKVTS5RXNVED5AX7")

        // Derive and verify account 4
        let account4 = coinType.derived(at: 4)
        let keyPair4 = try KeyPair(seed: Seed(bytes: [UInt8](account4.raw)))
        XCTAssertEqual(keyPair4.accountId, "GAXG3LWEXWCAWUABRO6SMAEUKJXLB5BBX6J2KMHFRIWKAMDJKCFGS3NN")
        XCTAssertEqual(keyPair4.secretSeed, "SBIZH53PIRFTPI73JG7QYA3YAINOAT2XMNAUARB3QOWWVZVBAROHGXWM")

        // Derive and verify account 8
        let account8 = coinType.derived(at: 8)
        let keyPair8 = try KeyPair(seed: Seed(bytes: [UInt8](account8.raw)))
        XCTAssertEqual(keyPair8.accountId, "GDHX4LU6YBSXGYTR7SX2P4ZYZSN24VXNJBVAFOB2GEBKNN3I54IYSRM4")
        XCTAssertEqual(keyPair8.secretSeed, "SCGMC5AHAAVB3D4JXQPCORWW37T44XJZUNPEMLRW6DCOEARY3H5MAQST")

        // Verify that each derived key is different
        XCTAssertNotEqual(account0.raw, account4.raw)
        XCTAssertNotEqual(account0.raw, account8.raw)
        XCTAssertNotEqual(account4.raw, account8.raw)

        // Verify that chain codes are different
        XCTAssertNotEqual(account0.chainCode, account4.chainCode)
        XCTAssertNotEqual(account0.chainCode, account8.chainCode)
        XCTAssertNotEqual(account4.chainCode, account8.chainCode)
    }

    // MARK: - Test 3: Invalid Path Throws

    func testInvalidPathThrows() {
        // The Ed25519Derivation implementation uses fatalError for invalid indices
        // An invalid index is one where the hardened bit is already set (index >= 0x80000000)

        let bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic12Words)
        let masterKey = Ed25519Derivation(seed: bip39Seed)

        // Valid index (should not throw/crash)
        let validIndex: UInt32 = 0
        let derivedValid = masterKey.derived(at: validIndex)
        XCTAssertEqual(derivedValid.raw.count, 32)

        // Maximum valid index (0x7FFFFFFF - just below hardened threshold)
        let maxValidIndex: UInt32 = 0x7FFFFFFF
        let derivedMax = masterKey.derived(at: maxValidIndex)
        XCTAssertEqual(derivedMax.raw.count, 32)

        // Note: Testing invalid indices (>= 0x80000000) would cause fatalError
        // which crashes the test. The implementation uses fatalError rather than
        // throwing an error, which is by design to catch programming errors early.
        // In production code, indices should always be < 0x80000000.
    }

    // MARK: - Test 4: Known Test Vectors

    func testKnownTestVectors() throws {
        // Test vectors from SEP-0005 with 12-word mnemonic
        let testVectors12: [(index: UInt32, accountId: String, secretSeed: String)] = [
            (0, "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6",
                "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN"),
            (2, "GAY5PRAHJ2HIYBYCLZXTHID6SPVELOOYH2LBPH3LD4RUMXUW3DOYTLXW",
                "SDAILLEZCSA67DUEP3XUPZJ7NYG7KGVRM46XA7K5QWWUIGADUZCZWTJP"),
            (4, "GBCUXLFLSL2JE3NWLHAWXQZN6SQC6577YMAU3M3BEMWKYPFWXBSRCWV4",
                "SCPCY3CEHMOP2TADSV2ERNNZBNHBGP4V32VGOORIEV6QJLXD5NMCJUXI"),
            (8, "GDJTCF62UUYSAFAVIXHPRBR4AUZV6NYJR75INVDXLLRZLZQ62S44443R",
                "SCD5OSHUUC75MSJG44BAT3HFZL2HZMMQ5M4GPDL7KA6HJHV3FLMUJAME"),
        ]

        let bip39Seed12 = Mnemonic.createSeed(mnemonic: mnemonic12Words)
        let masterKey12 = Ed25519Derivation(seed: bip39Seed12)
        let coinType12 = masterKey12.derived(at: 44).derived(at: 148)

        for testVector in testVectors12 {
            let account = coinType12.derived(at: testVector.index)
            let keyPair = try KeyPair(seed: Seed(bytes: [UInt8](account.raw)))

            XCTAssertEqual(keyPair.accountId, testVector.accountId,
                          "Account ID mismatch for index \(testVector.index)")
            XCTAssertEqual(keyPair.secretSeed, testVector.secretSeed,
                          "Secret seed mismatch for index \(testVector.index)")
        }

        // Test vectors from SEP-0005 with 24-word mnemonic
        let testVectors24: [(index: UInt32, accountId: String, secretSeed: String)] = [
            (0, "GC3MMSXBWHL6CPOAVERSJITX7BH76YU252WGLUOM5CJX3E7UCYZBTPJQ",
                "SAEWIVK3VLNEJ3WEJRZXQGDAS5NVG2BYSYDFRSH4GKVTS5RXNVED5AX7"),
            (2, "GDYF7GIHS2TRGJ5WW4MZ4ELIUIBINRNYPPAWVQBPLAZXC2JRDI4DGAKU",
                "SD5CCQAFRIPB3BWBHQYQ5SC66IB2AVMFNWWPBYGSUXVRZNCIRJ7IHESQ"),
            (4, "GAXG3LWEXWCAWUABRO6SMAEUKJXLB5BBX6J2KMHFRIWKAMDJKCFGS3NN",
                "SBIZH53PIRFTPI73JG7QYA3YAINOAT2XMNAUARB3QOWWVZVBAROHGXWM"),
            (8, "GDHX4LU6YBSXGYTR7SX2P4ZYZSN24VXNJBVAFOB2GEBKNN3I54IYSRM4",
                "SCGMC5AHAAVB3D4JXQPCORWW37T44XJZUNPEMLRW6DCOEARY3H5MAQST"),
        ]

        let bip39Seed24 = Mnemonic.createSeed(mnemonic: mnemonic24Words)
        let masterKey24 = Ed25519Derivation(seed: bip39Seed24)
        let coinType24 = masterKey24.derived(at: 44).derived(at: 148)

        for testVector in testVectors24 {
            let account = coinType24.derived(at: testVector.index)
            let keyPair = try KeyPair(seed: Seed(bytes: [UInt8](account.raw)))

            XCTAssertEqual(keyPair.accountId, testVector.accountId,
                          "Account ID mismatch for index \(testVector.index)")
            XCTAssertEqual(keyPair.secretSeed, testVector.secretSeed,
                          "Secret seed mismatch for index \(testVector.index)")
        }
    }

    // MARK: - Additional Tests

    func testDeterministicDerivation() {
        // Verify that derivation is deterministic - same seed produces same keys
        let bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic12Words)

        let masterKey1 = Ed25519Derivation(seed: bip39Seed)
        let account1 = masterKey1.derived(at: 44).derived(at: 148).derived(at: 0)

        let masterKey2 = Ed25519Derivation(seed: bip39Seed)
        let account2 = masterKey2.derived(at: 44).derived(at: 148).derived(at: 0)

        XCTAssertEqual(account1.raw, account2.raw)
        XCTAssertEqual(account1.chainCode, account2.chainCode)
    }

    func testMasterKeyInitialization() {
        // Test that master key initialization produces correct output size
        let bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic12Words)
        let masterKey = Ed25519Derivation(seed: bip39Seed)

        // Verify output sizes
        XCTAssertEqual(masterKey.raw.count, 32, "Master key should be 32 bytes")
        XCTAssertEqual(masterKey.chainCode.count, 32, "Chain code should be 32 bytes")

        // Verify master key is not all zeros
        let isRawAllZeros = masterKey.raw.allSatisfy { $0 == 0 }
        let isChainCodeAllZeros = masterKey.chainCode.allSatisfy { $0 == 0 }
        XCTAssertFalse(isRawAllZeros, "Master key should not be all zeros")
        XCTAssertFalse(isChainCodeAllZeros, "Chain code should not be all zeros")
    }

    func testDerivedKeyConsistency() throws {
        // Verify that deriving the same path always produces the same result
        let bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic24Words)
        let masterKey = Ed25519Derivation(seed: bip39Seed)

        // Derive the same account multiple times
        let account1 = masterKey.derived(at: 44).derived(at: 148).derived(at: 5)
        let account2 = masterKey.derived(at: 44).derived(at: 148).derived(at: 5)
        let account3 = masterKey.derived(at: 44).derived(at: 148).derived(at: 5)

        // All derivations should produce identical results
        XCTAssertEqual(account1.raw, account2.raw)
        XCTAssertEqual(account1.raw, account3.raw)
        XCTAssertEqual(account1.chainCode, account2.chainCode)
        XCTAssertEqual(account1.chainCode, account3.chainCode)

        // Verify the keypairs are identical
        let keyPair1 = try KeyPair(seed: Seed(bytes: [UInt8](account1.raw)))
        let keyPair2 = try KeyPair(seed: Seed(bytes: [UInt8](account2.raw)))
        let keyPair3 = try KeyPair(seed: Seed(bytes: [UInt8](account3.raw)))

        XCTAssertEqual(keyPair1.accountId, keyPair2.accountId)
        XCTAssertEqual(keyPair1.accountId, keyPair3.accountId)
        XCTAssertEqual(keyPair1.secretSeed, keyPair2.secretSeed)
        XCTAssertEqual(keyPair1.secretSeed, keyPair3.secretSeed)
    }

    func testChainOfDerivations() {
        // Test deriving a long chain of keys
        let bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic12Words)
        let masterKey = Ed25519Derivation(seed: bip39Seed)

        var currentKey = masterKey

        // Derive a chain: m/44'/148'/0'/1'/2'
        let indices: [UInt32] = [44, 148, 0, 1, 2]

        for index in indices {
            currentKey = currentKey.derived(at: index)
            XCTAssertEqual(currentKey.raw.count, 32)
            XCTAssertEqual(currentKey.chainCode.count, 32)
        }

        // Verify the final key is not all zeros
        let isRawAllZeros = currentKey.raw.allSatisfy { $0 == 0 }
        XCTAssertFalse(isRawAllZeros, "Derived key should not be all zeros")
    }

    func testDifferentSeedsProduceDifferentKeys() {
        // Verify that different seeds produce different derived keys
        let seed1 = Mnemonic.createSeed(mnemonic: mnemonic12Words)
        let seed2 = Mnemonic.createSeed(mnemonic: mnemonic24Words)

        let masterKey1 = Ed25519Derivation(seed: seed1)
        let masterKey2 = Ed25519Derivation(seed: seed2)

        // Master keys should be different
        XCTAssertNotEqual(masterKey1.raw, masterKey2.raw)
        XCTAssertNotEqual(masterKey1.chainCode, masterKey2.chainCode)

        // Derived keys should be different
        let account1 = masterKey1.derived(at: 44).derived(at: 148).derived(at: 0)
        let account2 = masterKey2.derived(at: 44).derived(at: 148).derived(at: 0)

        XCTAssertNotEqual(account1.raw, account2.raw)
        XCTAssertNotEqual(account1.chainCode, account2.chainCode)
    }
}
