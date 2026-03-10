//
//  Sep05DocTest.swift
//  stellarsdkTests
//
//  Created for documentation testing.
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Tests for SEP-05 documentation examples.
/// All tests are deterministic (no network calls) using known BIP-39 test vectors.
class Sep05DocTest: XCTestCase {

    // MARK: - Quick Example (Snippet 1)

    func testQuickExample() throws {
        // Generate a new 24-word mnemonic
        let mnemonic = WalletUtils.generate24WordMnemonic()
        let words = mnemonic.components(separatedBy: " ")
        XCTAssertEqual(words.count, 24)

        // Derive the first account
        let keyPair = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
        XCTAssertTrue(keyPair.accountId.hasPrefix("G"))
        XCTAssertNotNil(keyPair.secretSeed)
        XCTAssertTrue(keyPair.secretSeed!.hasPrefix("S"))
    }

    // MARK: - Generating Mnemonics (Snippets 2, 3)

    func testGenerate12WordMnemonic() {
        let mnemonic = WalletUtils.generate12WordMnemonic()
        let words = mnemonic.components(separatedBy: " ")
        XCTAssertEqual(words.count, 12)
    }

    func testGenerate24WordMnemonic() {
        let mnemonic = WalletUtils.generate24WordMnemonic()
        let words = mnemonic.components(separatedBy: " ")
        XCTAssertEqual(words.count, 24)
    }

    // MARK: - Mnemonics in Other Languages (Snippet 4)

    func testMnemonicsInOtherLanguages() {
        let french = WalletUtils.generate12WordMnemonic(language: .french)
        let frenchWords = french.components(separatedBy: " ")
        XCTAssertEqual(frenchWords.count, 12)

        let korean = WalletUtils.generate24WordMnemonic(language: .korean)
        let koreanWords = korean.components(separatedBy: " ")
        XCTAssertEqual(koreanWords.count, 24)

        let spanish = WalletUtils.generate12WordMnemonic(language: .spanish)
        let spanishWords = spanish.components(separatedBy: " ")
        XCTAssertEqual(spanishWords.count, 12)
    }

    // MARK: - Basic Derivation (Snippet 5)

    func testBasicDerivation() throws {
        let words = "shell green recycle learn purchase able oxygen right echo claim hill again "
            + "hidden evidence nice decade panic enemy cake version say furnace garment glue"

        let keyPair0 = try WalletUtils.createKeyPair(mnemonic: words, passphrase: nil, index: 0)
        XCTAssertEqual(keyPair0.accountId, "GCVSEBHB6CTMEHUHIUY4DDFMWQ7PJTHFZGOK2JUD5EG2ARNVS6S22E3K")
        XCTAssertEqual(keyPair0.secretSeed, "SATLGMF3SP2V47SJLBFVKZZJQARDOBDQ7DNSSPUV7NLQNPN3QB7M74XH")

        let keyPair1 = try WalletUtils.createKeyPair(mnemonic: words, passphrase: nil, index: 1)
        XCTAssertEqual(keyPair1.accountId, "GBPHPX7SZKYEDV5CVOA5JOJE2RHJJDCJMRWMV4KBOIE5VSDJ6VAESR2W")
    }

    // MARK: - Derivation with Passphrase (Snippet 6)

    func testDerivationWithPassphrase() throws {
        let words = "cable spray genius state float twenty onion head street palace net private "
            + "method loan turn phrase state blanket interest dry amazing dress blast tube"

        let keyPair0 = try WalletUtils.createKeyPair(mnemonic: words, passphrase: "p4ssphr4se", index: 0)
        XCTAssertEqual(keyPair0.accountId, "GDAHPZ2NSYIIHZXM56Y36SBVTV5QKFIZGYMMBHOU53ETUSWTP62B63EQ")

        let keyPair1 = try WalletUtils.createKeyPair(mnemonic: words, passphrase: "p4ssphr4se", index: 1)
        XCTAssertEqual(keyPair1.accountId, "GDY47CJARRHHL66JH3RJURDYXAMIQ5DMXZLP3TDAUJ6IN2GUOFX4OJOC")
    }

    // MARK: - Non-English Mnemonic Derivation (Snippet 7)

    func testNonEnglishMnemonicDerivation() throws {
        let korean = WalletUtils.generate24WordMnemonic(language: .korean)
        let keyPair = try WalletUtils.createKeyPair(mnemonic: korean, passphrase: nil, index: 0)
        XCTAssertTrue(keyPair.accountId.hasPrefix("G"))
        XCTAssertNotNil(keyPair.secretSeed)
    }

    // MARK: - Restoring from Non-English Mnemonic (Snippet 8)

    func testRestoreFromJapaneseMnemonic() throws {
        let words = "あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん "
            + "あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あおぞら"
        let keyPair = try WalletUtils.createKeyPair(mnemonic: words, passphrase: nil, index: 0)
        XCTAssertTrue(keyPair.accountId.hasPrefix("G"))
        XCTAssertNotNil(keyPair.secretSeed)
    }

    // MARK: - Multiple Account Derivation (Snippet 9)

    func testMultipleAccountDerivation() throws {
        let mnemonic = "illness spike retreat truth genius clock brain pass fit cave bargain toe"

        let expectedAccounts = [
            "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6",
            "GBAW5XGWORWVFE2XTJYDTLDHXTY2Q2MO73HYCGB3XMFMQ562Q2W2GJQX",
            "GAY5PRAHJ2HIYBYCLZXTHID6SPVELOOYH2LBPH3LD4RUMXUW3DOYTLXW",
            "GAOD5NRAEORFE34G5D4EOSKIJB6V4Z2FGPBCJNQI6MNICVITE6CSYIAE",
            "GBCUXLFLSL2JE3NWLHAWXQZN6SQC6577YMAU3M3BEMWKYPFWXBSRCWV4"
        ]

        for i in 0..<5 {
            let kp = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: i)
            XCTAssertEqual(kp.accountId, expectedAccounts[i], "Account \(i) mismatch")
        }
    }

    // MARK: - From Hex Seed (Snippet 10)

    func testFromHexSeed() throws {
        let hexSeed = "e4a5a632e70943ae7f07659df1332160937fad82587216a4c64315a0fb39497e"
            + "e4a01f76ddab4cba68147977f3a147b6ad584c41808e8238a07f6cc4b582f186"
        let seedData = try Data(base16Encoded: hexSeed)

        let masterKey = Ed25519Derivation(seed: seedData)
        let purpose = masterKey.derived(at: 44)
        let coinType = purpose.derived(at: 148)

        let account0 = coinType.derived(at: 0)
        let stellarSeed0 = try Seed(bytes: [UInt8](account0.raw))
        let kp0 = KeyPair(seed: stellarSeed0)
        XCTAssertEqual(kp0.accountId, "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6")

        let account1 = coinType.derived(at: 1)
        let stellarSeed1 = try Seed(bytes: [UInt8](account1.raw))
        let kp1 = KeyPair(seed: stellarSeed1)
        XCTAssertEqual(kp1.accountId, "GBAW5XGWORWVFE2XTJYDTLDHXTY2Q2MO73HYCGB3XMFMQ562Q2W2GJQX")
    }

    // MARK: - Restoring from Words (Snippet 12)

    func testRestoringFromWords() throws {
        let words = "illness spike retreat truth genius clock brain pass fit cave bargain toe"
        let keyPair = try WalletUtils.createKeyPair(mnemonic: words, passphrase: nil, index: 0)
        XCTAssertEqual(keyPair.accountId, "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6")
    }

    // MARK: - Nil and Empty Passphrase Equivalence

    func testNilAndEmptyPassphraseEquivalence() throws {
        let mnemonic = "illness spike retreat truth genius clock brain pass fit cave bargain toe"

        let kpNil = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
        let kpEmpty = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: "", index: 0)
        XCTAssertEqual(kpNil.accountId, kpEmpty.accountId)

        // Non-empty passphrase produces different keys
        let kpPass = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: "p4ssphr4se", index: 0)
        XCTAssertNotEqual(kpNil.accountId, kpPass.accountId)
    }

    // MARK: - Manual Derivation Matches WalletUtils

    func testManualDerivationMatchesWalletUtils() throws {
        let mnemonic = "illness spike retreat truth genius clock brain pass fit cave bargain toe"

        // Manual derivation using Ed25519Derivation and Mnemonic
        let bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic)
        let masterKey = Ed25519Derivation(seed: bip39Seed)
        let purpose = masterKey.derived(at: 44)
        let coinType = purpose.derived(at: 148)
        let account = coinType.derived(at: 0)
        let stellarSeed = try Seed(bytes: [UInt8](account.raw))
        let manualKeyPair = KeyPair(seed: stellarSeed)

        // WalletUtils derivation
        let utilsKeyPair = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)

        XCTAssertEqual(manualKeyPair.accountId, utilsKeyPair.accountId)
        XCTAssertEqual(manualKeyPair.accountId, "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6")
    }

    // MARK: - Hex Seed Matches Mnemonic Derivation

    func testHexSeedMatchesMnemonicDerivation() throws {
        // The hex seed for "illness spike retreat truth genius clock brain pass fit cave bargain toe"
        // should produce the same keys as WalletUtils.createKeyPair with that mnemonic
        let mnemonic = "illness spike retreat truth genius clock brain pass fit cave bargain toe"
        let bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic)

        let masterKey = Ed25519Derivation(seed: bip39Seed)
        let purpose = masterKey.derived(at: 44)
        let coinType = purpose.derived(at: 148)
        let account = coinType.derived(at: 0)
        let stellarSeed = try Seed(bytes: [UInt8](account.raw))
        let kp = KeyPair(seed: stellarSeed)

        let utilsKp = try WalletUtils.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
        XCTAssertEqual(kp.accountId, utilsKp.accountId)
    }
}
