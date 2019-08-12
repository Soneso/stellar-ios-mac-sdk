//
//  MnemonicKeyPairGeneration.swift
//  stellarsdkTests
//
//  Created by Satraj Bambra on 2018-03-07.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class MnemonicKeyPairGeneration: XCTestCase {
    let sdk = StellarSDK()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // All tests are conducted against Stellar SEP: 0005 tests defined here https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md
    
    /*func test12WordBIPAndMasterKeyGeneration() {
        let mnemonic = "illness spike retreat truth genius clock brain pass fit cave bargain toe"
        let bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic)
    
        XCTAssertEqual(bip39Seed.toHexString(), "e4a5a632e70943ae7f07659df1332160937fad82587216a4c64315a0fb39497ee4a01f76ddab4cba68147977f3a147b6ad584c41808e8238a07f6cc4b582f186")
        
        
        let masterPrivateKey = Ed25519Derivation(seed: bip39Seed)
        let purpose = masterPrivateKey.derived(at: 44)
        let coinType = purpose.derived(at: 148)
        
        XCTAssertEqual(coinType.raw.toHexString(), "e0eec84fe165cd427cb7bc9b6cfdef0555aa1cb6f9043ff1fe986c3c8ddd22e3")
        
        let account0 = coinType.derived(at: 0)
        let keyPair0 = try! KeyPair.init(seed: Seed(bytes: account0.raw.bytes))
        
        XCTAssertEqual(keyPair0.accountId, "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6")
        XCTAssertEqual(keyPair0.secretSeed, "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN")
        
        let account4 = coinType.derived(at: 4)
        let keyPair4 = try! KeyPair.init(seed: Seed(bytes: account4.raw.bytes))
        
        XCTAssertEqual(keyPair4.accountId, "GBCUXLFLSL2JE3NWLHAWXQZN6SQC6577YMAU3M3BEMWKYPFWXBSRCWV4")
        XCTAssertEqual(keyPair4.secretSeed, "SCPCY3CEHMOP2TADSV2ERNNZBNHBGP4V32VGOORIEV6QJLXD5NMCJUXI")
        
        let account8 = coinType.derived(at: 8)
        let keyPair8 = try! KeyPair.init(seed: Seed(bytes: account8.raw.bytes))
        
        XCTAssertEqual(keyPair8.accountId, "GDJTCF62UUYSAFAVIXHPRBR4AUZV6NYJR75INVDXLLRZLZQ62S44443R")
        XCTAssertEqual(keyPair8.secretSeed, "SCD5OSHUUC75MSJG44BAT3HFZL2HZMMQ5M4GPDL7KA6HJHV3FLMUJAME")
    }
    
    func test24WordBIPAndMasterKeyGeneration() {
        let mnemonic = "bench hurt jump file august wise shallow faculty impulse spring exact slush thunder author capable act festival slice deposit sauce coconut afford frown better"
        let bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic)
        
        XCTAssertEqual(bip39Seed.toHexString(), "937ae91f6ab6f12461d9936dfc1375ea5312d097f3f1eb6fed6a82fbe38c85824da8704389831482db0433e5f6c6c9700ff1946aa75ad8cc2654d6e40f567866")
        
        
        let masterPrivateKey = Ed25519Derivation(seed: bip39Seed)
        let purpose = masterPrivateKey.derived(at: 44)
        let coinType = purpose.derived(at: 148)
        
        XCTAssertEqual(coinType.raw.toHexString(), "df474e0dc2711089b89af6b089aceeb77e73120e9f895bd330a36fa952835ea8")
        
        let account0 = coinType.derived(at: 0)
        let keyPair0 = try! KeyPair.init(seed: Seed(bytes: account0.raw.bytes))
        
        XCTAssertEqual(keyPair0.accountId, "GC3MMSXBWHL6CPOAVERSJITX7BH76YU252WGLUOM5CJX3E7UCYZBTPJQ")
        XCTAssertEqual(keyPair0.secretSeed, "SAEWIVK3VLNEJ3WEJRZXQGDAS5NVG2BYSYDFRSH4GKVTS5RXNVED5AX7")
        
        let account4 = coinType.derived(at: 4)
        let keyPair4 = try! KeyPair.init(seed: Seed(bytes: account4.raw.bytes))
        
        XCTAssertEqual(keyPair4.accountId, "GAXG3LWEXWCAWUABRO6SMAEUKJXLB5BBX6J2KMHFRIWKAMDJKCFGS3NN")
        XCTAssertEqual(keyPair4.secretSeed, "SBIZH53PIRFTPI73JG7QYA3YAINOAT2XMNAUARB3QOWWVZVBAROHGXWM")
        
        let account8 = coinType.derived(at: 8)
        let keyPair8 = try! KeyPair.init(seed: Seed(bytes: account8.raw.bytes))
        
        XCTAssertEqual(keyPair8.accountId, "GDHX4LU6YBSXGYTR7SX2P4ZYZSN24VXNJBVAFOB2GEBKNN3I54IYSRM4")
        XCTAssertEqual(keyPair8.secretSeed, "SCGMC5AHAAVB3D4JXQPCORWW37T44XJZUNPEMLRW6DCOEARY3H5MAQST")
    }
    
    func test12WordWalletKeyPairGeneration() {
        let mnemonic = "illness spike retreat truth genius clock brain pass fit cave bargain toe"
        
        let keyPair0 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
        
        XCTAssertEqual(keyPair0.accountId, "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6")
        XCTAssertEqual(keyPair0.secretSeed, "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN")
        
        let keyPair2 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 2)
        
        XCTAssertEqual(keyPair2.accountId, "GAY5PRAHJ2HIYBYCLZXTHID6SPVELOOYH2LBPH3LD4RUMXUW3DOYTLXW")
        XCTAssertEqual(keyPair2.secretSeed, "SDAILLEZCSA67DUEP3XUPZJ7NYG7KGVRM46XA7K5QWWUIGADUZCZWTJP")
        
        let keyPair4 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 4)
        
        XCTAssertEqual(keyPair4.accountId, "GBCUXLFLSL2JE3NWLHAWXQZN6SQC6577YMAU3M3BEMWKYPFWXBSRCWV4")
        XCTAssertEqual(keyPair4.secretSeed, "SCPCY3CEHMOP2TADSV2ERNNZBNHBGP4V32VGOORIEV6QJLXD5NMCJUXI")
        
        let keyPair8 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 8)
        
        XCTAssertEqual(keyPair8.accountId, "GDJTCF62UUYSAFAVIXHPRBR4AUZV6NYJR75INVDXLLRZLZQ62S44443R")
        XCTAssertEqual(keyPair8.secretSeed, "SCD5OSHUUC75MSJG44BAT3HFZL2HZMMQ5M4GPDL7KA6HJHV3FLMUJAME")
    }*/
    
    func test24WordWalletKeyPairGeneration() {
        let mnemonic = "bench hurt jump file august wise shallow faculty impulse spring exact slush thunder author capable act festival slice deposit sauce coconut afford frown better"
        
        let keyPair0 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 0)
        
        XCTAssertEqual(keyPair0.accountId, "GC3MMSXBWHL6CPOAVERSJITX7BH76YU252WGLUOM5CJX3E7UCYZBTPJQ")
        XCTAssertEqual(keyPair0.secretSeed, "SAEWIVK3VLNEJ3WEJRZXQGDAS5NVG2BYSYDFRSH4GKVTS5RXNVED5AX7")
        
        let keyPair2 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 2)
        
        XCTAssertEqual(keyPair2.accountId, "GDYF7GIHS2TRGJ5WW4MZ4ELIUIBINRNYPPAWVQBPLAZXC2JRDI4DGAKU")
        XCTAssertEqual(keyPair2.secretSeed, "SD5CCQAFRIPB3BWBHQYQ5SC66IB2AVMFNWWPBYGSUXVRZNCIRJ7IHESQ")
        
        let keyPair4 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 4)
        
        XCTAssertEqual(keyPair4.accountId, "GAXG3LWEXWCAWUABRO6SMAEUKJXLB5BBX6J2KMHFRIWKAMDJKCFGS3NN")
        XCTAssertEqual(keyPair4.secretSeed, "SBIZH53PIRFTPI73JG7QYA3YAINOAT2XMNAUARB3QOWWVZVBAROHGXWM")
        
        let keyPair8 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: nil, index: 8)
        
        XCTAssertEqual(keyPair8.accountId, "GDHX4LU6YBSXGYTR7SX2P4ZYZSN24VXNJBVAFOB2GEBKNN3I54IYSRM4")
        XCTAssertEqual(keyPair8.secretSeed, "SCGMC5AHAAVB3D4JXQPCORWW37T44XJZUNPEMLRW6DCOEARY3H5MAQST")
    }
    
    func test24WordWalletKeyPairGenerationWithPassphrase() {
        let mnemonic = "cable spray genius state float twenty onion head street palace net private method loan turn phrase state blanket interest dry amazing dress blast tube"
        
        let keyPair0 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: "p4ssphr4se", index: 0)
        
        XCTAssertEqual(keyPair0.accountId, "GDAHPZ2NSYIIHZXM56Y36SBVTV5QKFIZGYMMBHOU53ETUSWTP62B63EQ")
        XCTAssertEqual(keyPair0.secretSeed, "SAFWTGXVS7ELMNCXELFWCFZOPMHUZ5LXNBGUVRCY3FHLFPXK4QPXYP2X")
        
        let keyPair2 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: "p4ssphr4se", index: 2)
        
        XCTAssertEqual(keyPair2.accountId, "GCLAQF5H5LGJ2A6ACOMNEHSWYDJ3VKVBUBHDWFGRBEPAVZ56L4D7JJID")
        XCTAssertEqual(keyPair2.secretSeed, "SAF2LXRW6FOSVQNC4HHIIDURZL4SCGCG7UEGG23ZQG6Q2DKIGMPZV6BZ")
        
        let keyPair4 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: "p4ssphr4se", index: 4)
        
        XCTAssertEqual(keyPair4.accountId, "GA6NHA4KPH5LFYD6LZH35SIX3DU5CWU3GX6GCKPJPPTQCCQPP627E3CB")
        XCTAssertEqual(keyPair4.secretSeed, "SA5TRXTO7BG2Z6QTQT3O2LC7A7DLZZ2RBTGUNCTG346PLVSSHXPNDVNT")
        
        let keyPair8 = try! Wallet.createKeyPair(mnemonic: mnemonic, passphrase: "p4ssphr4se", index: 8)
        
        XCTAssertEqual(keyPair8.accountId, "GDS5I7L7LWFUVSYVAOHXJET2565MGGHJ4VHGVJXIKVKNO5D4JWXIZ3XU")
        XCTAssertEqual(keyPair8.secretSeed, "SAIZA26BUP55TDCJ4U7I2MSQEAJDPDSZSBKBPWQTD5OQZQSJAGNN2IQB")
    }
}
