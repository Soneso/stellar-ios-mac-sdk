//
//  StrKeyTest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.07.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class StrKeyTest: XCTestCase {
    let keyPair = KeyPair(seed: try! Seed(bytes: [UInt8](Network.testnet.networkId)))
    var accountIdEncoded:String = ""
    var seedEncoded:String = ""

    override func setUp() {
        super.setUp()
        accountIdEncoded = keyPair.accountId
        seedEncoded = keyPair.secretSeed
    }
    
    func testDecodeCheck() throws {
        // decodes account id correctly
        let decodedAccountId = try accountIdEncoded.decodeEd25519PublicKey()
        XCTAssertEqual(decodedAccountId, Data(keyPair.publicKey.bytes))
        
        // decodes secret seed correctly
        let decodedSeed = try seedEncoded.decodeEd25519SecretSeed()
        XCTAssertEqual(decodedSeed, Data(keyPair.seed!.bytes))
        
        // throws an error when the version byte is wrong
        XCTAssertThrowsError(try "GBPXXOA5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL".decodeEd25519SecretSeed())
        XCTAssertThrowsError(try "SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36XCU".decodeEd25519PublicKey())
        
        // throws an error when invalid encoded string
        XCTAssertThrowsError(try "GBPXX0A5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL".decodeEd25519PublicKey()) // invalid account id
        XCTAssertThrowsError(try "GCFZB6L25D26RQFDWSSBDEYQ32JHLRMTT44ZYE3DZQUTYOL7WY43PLBG++".decodeEd25519PublicKey()) // invalid account id
        XCTAssertThrowsError(try "GB6OWYST45X57HCJY5XWOHDEBULB6XUROWPIKW77L5DSNANBEQGUPADT2T".decodeEd25519PublicKey()) // invalid account id
        
        XCTAssertThrowsError(try "SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYW".decodeEd25519SecretSeed()) // invalid secret seed
        XCTAssertThrowsError(try "SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYWMEGB2W2".decodeEd25519SecretSeed()) // invalid secret seed
        XCTAssertThrowsError(try "SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYWMEGB2W2T".decodeEd25519SecretSeed()) // invalid secret seed
        XCTAssertThrowsError(try "SCMB30FQCIQAWZ4WQTS6SVK37LGMAFJGXOZIHTH2PY6EXLP37G46H6DT".decodeEd25519SecretSeed()) // invalid secret seed
        XCTAssertThrowsError(try "SAYC2LQ322EEHZYWNSKBEW6N66IRTDREEBUXXU5HPVZGMAXKLIZNM45H++".decodeEd25519SecretSeed()) // invalid secret seed
        
        // throws an error when checksum is wrong
        XCTAssertThrowsError(try "GBPXXOA5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVT".decodeEd25519PublicKey()) // invalid account id checksum
        XCTAssertThrowsError(try "SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36XCX".decodeEd25519SecretSeed()) // invalid secret seed checksum
    }
    
    func testEncodeCheck() throws {
        
        // encodes a buffer correctly
        let publicKeyData = Data(keyPair.publicKey.bytes)
        let encodedAccountId = try publicKeyData.encodeEd25519PublicKey()
        XCTAssertEqual(encodedAccountId, accountIdEncoded)
        XCTAssertEqual(publicKeyData, try accountIdEncoded.decodeEd25519PublicKey())
        
        let secretSeedData = Data(keyPair.seed!.bytes)
        let encodedSecretSeed = try secretSeedData.encodeEd25519SecretSeed()
        XCTAssertEqual(encodedSecretSeed, seedEncoded)
        XCTAssertEqual(secretSeedData, try seedEncoded.decodeEd25519SecretSeed())
        
        var strKeyEncoded = try publicKeyData.encodePreAuthTx()
        XCTAssertTrue(strKeyEncoded.hasPrefix("T"))
        XCTAssertEqual(publicKeyData, try strKeyEncoded.decodePreAuthTx())
        
        strKeyEncoded = try publicKeyData.encodeSha256Hash()
        XCTAssertTrue(strKeyEncoded.hasPrefix("X"))
        XCTAssertEqual(publicKeyData, try strKeyEncoded.decodeSha256Hash())
    }
    
    func testIsValid() throws {
        // returns true for valid public key
        var keys = [
            "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB",
            "GB7KKHHVYLDIZEKYJPAJUOTBE5E3NJAXPSDZK7O6O44WR3EBRO5HRPVT",
            "GD6WVYRVID442Y4JVWFWKWCZKB45UGHJAABBJRS22TUSTWGJYXIUR7N2",
            "GBCG42WTVWPO4Q6OZCYI3D6ZSTFSJIXIS6INCIUF23L6VN3ADE4337AP",
            "GDFX463YPLCO2EY7NGFMI7SXWWDQAMASGYZXCG2LATOF3PP5NQIUKBPT",
            "GBXEODUMM3SJ3QSX2VYUWFU3NRP7BQRC2ERWS7E2LZXDJXL2N66ZQ5PT",
            "GAJHORKJKDDEPYCD6URDFODV7CVLJ5AAOJKR6PG2VQOLWFQOF3X7XLOG",
            "GACXQEAXYBEZLBMQ2XETOBRO4P66FZAJENDHOQRYPUIXZIIXLKMZEXBJ",
            "GDD3XRXU3G4DXHVRUDH7LJM4CD4PDZTVP4QHOO4Q6DELKXUATR657OZV",
            "GDTYVCTAUQVPKEDZIBWEJGKBQHB4UGGXI2SXXUEW7LXMD4B7MK37CWLJ"
          ]
        
        for key in keys {
            XCTAssertTrue(key.isValidEd25519PublicKey())
        }
        
        // returns false for invalid public key
        keys = [
            "GBPXX0A5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL",
            "GCFZB6L25D26RQFDWSSBDEYQ32JHLRMTT44ZYE3DZQUTYOL7WY43PLBG++",
            "GADE5QJ2TY7S5ZB65Q43DFGWYWCPHIYDJ2326KZGAGBN7AE5UY6JVDRRA",
            "GB6OWYST45X57HCJY5XWOHDEBULB6XUROWPIKW77L5DSNANBEQGUPADT2",
            "GB6OWYST45X57HCJY5XWOHDEBULB6XUROWPIKW77L5DSNANBEQGUPADT2T",
            "GDXIIZTKTLVYCBHURXL2UPMTYXOVNI7BRAEFQCP6EZCY4JLKY4VKFNLT",
            "SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY",
            "gWRYUerEKuz53tstxEuR3NCkiQDcV4wzFHmvLnZmj7PUqxW2wt",
            "test",
            "g4VPBPrHZkfE8CsjuG2S4yBQNd455UWmk" // Old network key
          ]
        
        for key in keys {
            XCTAssertFalse(key.isValidEd25519PublicKey())
        }
        
        // returns true for valid secret key
        keys = [
            "SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY",
            "SCZTUEKSEH2VYZQC6VLOTOM4ZDLMAGV4LUMH4AASZ4ORF27V2X64F2S2",
            "SCGNLQKTZ4XCDUGVIADRVOD4DEVNYZ5A7PGLIIZQGH7QEHK6DYODTFEH",
            "SDH6R7PMU4WIUEXSM66LFE4JCUHGYRTLTOXVUV5GUEPITQEO3INRLHER",
            "SC2RDTRNSHXJNCWEUVO7VGUSPNRAWFCQDPP6BGN4JFMWDSEZBRAPANYW",
            "SCEMFYOSFZ5MUXDKTLZ2GC5RTOJO6FGTAJCF3CCPZXSLXA2GX6QUYOA7"
          ]
        
        for key in keys {
            XCTAssertTrue(key.isValidEd25519SecretSeed())
        }
        
        // returns false for invalid secret key
        keys = [
              "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB",
              "SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDYT", // Too long
              "SAFGAMN5Z6IHVI3IVEPIILS7ITZDYSCEPLN4FN5Z3IY63DRH4CIYEV", // To short
              "SAFGAMN5Z6IHVI3IVEPIILS7ITZDYSCEPLN4FN5Z3IY63DRH4CIYEVIT", // Checksum
              "test",
            ]
        
        for key in keys {
            XCTAssertFalse(key.isValidEd25519SecretSeed())
        }
    }
    
    func testMuxedAccount() throws {
        let mPubKey = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"
        let rawMPubKey =  "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a8000000000000000".data(using: .hexadecimal)!
        
        // encodes & decodes M... addresses correctly
        XCTAssertEqual(try rawMPubKey.encodeMEd25519AccountId(), mPubKey)
        XCTAssertEqual(try mPubKey.decodeMed25519PublicKey(), rawMPubKey)
    }
    
    func testSignedPayloads() throws {
        var decoded = try "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAQACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IBZGM".decodeSignedPayload()
        var pk = try PublicKey([UInt8](decoded.ed25519.wrapped))
        XCTAssertEqual("GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ", pk.accountId)
        XCTAssertEqual("0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20", decoded.payload.base16EncodedString())
        
        decoded = try "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUAAAAFGBU".decodeSignedPayload()
        pk = try PublicKey([UInt8](decoded.ed25519.wrapped))
        XCTAssertEqual("GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ", pk.accountId)
        XCTAssertEqual("0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d", decoded.payload.base16EncodedString())
       
    }
    
    func testContractIds() throws {
        let contractId = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"
        let asHex = "363eaa3867841fbad0f4ed88c779e4fe66e56a2470dc98c0ec9c073d05c7b103"
        let decoded = try contractId.decodeContractId()
        XCTAssertEqual(asHex, decoded.base16EncodedString())
        XCTAssertEqual(asHex, try contractId.decodeContractIdToHex())
        XCTAssertEqual(contractId, try asHex.data(using: .hexadecimal)?.encodeContractId())
        XCTAssertTrue(contractId.isValidContractId())
        XCTAssertFalse("GA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE".isValidContractId())
    }
    
    func testLiquidityPoolIds() throws {
        let liquidityPoolId = "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN"
        let asHex = "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"
        let decoded = try liquidityPoolId.decodeLiquidityPoolId()
        XCTAssertEqual(asHex, decoded.base16EncodedString())
        XCTAssertEqual(asHex, try liquidityPoolId.decodeLiquidityPoolIdToHex())
        XCTAssertEqual(liquidityPoolId, try asHex.data(using: .hexadecimal)?.encodeLiquidityPoolId())
        XCTAssertTrue(liquidityPoolId.isValidLiquidityPoolId())
        XCTAssertFalse("LB7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN".isValidLiquidityPoolId())
    }
    
    func testClaimableBalanceIds() throws {
        let claimableBalanceId = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU"
        let asHex = "003f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"
        let decoded = try claimableBalanceId.decodeClaimableBalanceId()
        XCTAssertEqual(asHex, decoded.base16EncodedString())
        XCTAssertEqual(asHex, try claimableBalanceId.decodeClaimableBalanceIdToHex())
        XCTAssertEqual(claimableBalanceId, try asHex.data(using: .hexadecimal)?.encodeClaimableBalanceId())
        XCTAssertTrue(claimableBalanceId.isValidClaimableBalanceId())
        XCTAssertFalse("BBAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU".isValidClaimableBalanceId())
    }
    
    func testInvalidStrKeys() throws {
        // The unused trailing bit must be zero in the encoding of the last three
        // bytes (24 bits) as five base-32 symbols (25 bits)
        var strKey = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUR"
        XCTAssertFalse(strKey.isValidMed25519PublicKey())
        
        // Invalid length (congruent to 1 mod 8)
        strKey = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZA"
        XCTAssertFalse(strKey.isValidMed25519PublicKey())
        
        // Invalid algorithm (low 3 bits of version byte are 7)
        strKey = "G47QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVP2I"
        XCTAssertFalse(strKey.isValidMed25519PublicKey())
        
        // Invalid algorithm (low 3 bits of version byte are 7)
        strKey = "G47QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVP2I"
        XCTAssertFalse(strKey.isValidMed25519PublicKey())
        
        // Invalid length (congruent to 6 mod 8)
        strKey = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLKA"
        XCTAssertFalse(strKey.isValidMed25519PublicKey())
        
        // Invalid algorithm (low 3 bits of version byte are 7)
        strKey = "M47QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ"
        XCTAssertFalse(strKey.isValidMed25519PublicKey())
        
        // Padding bytes are not allowed
        strKey = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUK==="
        XCTAssertFalse(strKey.isValidMed25519PublicKey())
        
        // Invalid checksum
        strKey = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUO"
        XCTAssertFalse(strKey.isValidMed25519PublicKey())
        
        // Trailing bits should be zeroes
        strKey = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TV"
        XCTAssertFalse(strKey.isValidClaimableBalanceId())
        
        // Invalid length (Ed25519 should be 32 bytes, not 5)
        strKey = "GAAAAAAAACGC6"
        XCTAssertFalse(strKey.isValidEd25519PublicKey())
        
        // Invalid length (base-32 decoding should yield 35 bytes, not 36)
        strKey = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUACUSI"
        XCTAssertFalse(strKey.isValidEd25519PublicKey())
        
        // Invalid length (base-32 decoding should yield 43 bytes, not 44)
        strKey = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAAV75I"
        XCTAssertFalse(strKey.isValidMed25519PublicKey())
    }
    
}
