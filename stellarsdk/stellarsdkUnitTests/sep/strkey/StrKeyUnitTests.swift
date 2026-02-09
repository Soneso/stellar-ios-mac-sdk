//
//  StrKeyUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.07.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class StrKeyUnitTests: XCTestCase {
    let keyPair = KeyPair(seed: try! Seed(bytes: [UInt8](Network.testnet.networkId)))
    var accountIdEncoded:String = ""
    var seedEncoded:String = ""

    override func setUp() {
        super.setUp()
        accountIdEncoded = keyPair.accountId
        seedEncoded = keyPair.secretSeed ?? ""
    }

    // MARK: - Ed25519 Public Key and Secret Seed Tests

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
    
    // MARK: - Muxed Account Tests

    func testMuxedAccount() throws {
        let mPubKey = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"
        let rawMPubKey =  "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a8000000000000000".data(using: .hexadecimal)!

        // encodes & decodes M... addresses correctly
        XCTAssertEqual(try rawMPubKey.encodeMEd25519AccountId(), mPubKey)
        XCTAssertEqual(try mPubKey.decodeMed25519PublicKey(), rawMPubKey)
    }

    func testMuxedAccountXDREncodeDecode() throws {
        // Test M... address decoding to MuxedAccountXDR and back
        let accountId = "MAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSAAAAAAAAAAE2LP26"
        let mux = try accountId.decodeMuxedAccount()
        var muxEncoded = try XDREncoder.encode(mux)
        let muxData = Data(bytes: &muxEncoded, count: muxEncoded.count)
        let muxId = try muxData.encodeMuxedAccount()
        XCTAssertEqual(accountId, muxId)
    }

    func testMuxedAccountFromPublicKey() throws {
        // Test G... address (public key) decoding to MuxedAccountXDR and back
        let accountId = "GBJRYVWMCM4IYZDEB7AUB7Q4IY64HLLWD5A3ZLONHDEDZ66YSU4IXS5N"
        let mux = try accountId.decodeMuxedAccount()
        var muxEncoded = try XDREncoder.encode(mux)
        let muxData = Data(bytes: &muxEncoded, count: muxEncoded.count)
        let muxId = try muxData.encodeMuxedAccount()
        XCTAssertEqual(accountId, muxId)
    }
    
    // MARK: - Signed Payload Tests

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

    func testSignedPayload32BytesRoundTrip() throws {
        // Test 32-byte payload encoding and round-trip
        let accountId = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
        let expectedStrKey = "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAQACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IBZGM"
        let dataStr = "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20"
        let data = try Data(base16Encoded: dataStr)
        let pk = try PublicKey(accountId: accountId)
        let payloadSigner = Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: data)
        let encoded = try payloadSigner.encodeSignedPayload()
        XCTAssertEqual(encoded, expectedStrKey)
        let signedPayload = try encoded.decodeSignedPayload()
        XCTAssertEqual(try signedPayload.publicKey().accountId, accountId)
        XCTAssertEqual(signedPayload.payload.base16EncodedString(), dataStr)
    }

    func testSignedPayload29BytesRoundTrip() throws {
        // Test 29-byte payload (non-32) encoding and round-trip
        let accountId = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
        let expectedStrKey = "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUAAAAFGBU"
        let dataStr = "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d"
        let data = try Data(base16Encoded: dataStr)
        let pk = try PublicKey(accountId: accountId)
        let payloadSigner = Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: data)
        let encoded = try payloadSigner.encodeSignedPayload()
        XCTAssertEqual(encoded, expectedStrKey)
        let signedPayload = try encoded.decodeSignedPayload()
        XCTAssertEqual(try signedPayload.publicKey().accountId, accountId)
        XCTAssertEqual(signedPayload.payload.base16EncodedString(), dataStr)
    }

    func testSignedPayloadTooLong() throws {
        // Test that payload longer than 64 bytes throws an error
        let accountId = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
        let dataStr = "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f200102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f2001"
        let data = try Data(base16Encoded: dataStr)
        XCTAssertThrowsError(try Signer.signedPayload(accountId: accountId, payload: data))
    }
    
    // MARK: - Contract ID Tests

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
    
    // MARK: - Liquidity Pool ID Tests

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
    
    // MARK: - Claimable Balance ID Tests

    func testClaimableBalanceIds() throws {
        let claimableBalanceId = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU"
        var asHex = "003f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"
        let decoded = try claimableBalanceId.decodeClaimableBalanceId()
        XCTAssertEqual(asHex, decoded.base16EncodedString())
        XCTAssertEqual(asHex, try claimableBalanceId.decodeClaimableBalanceIdToHex())
        XCTAssertEqual(claimableBalanceId, try asHex.data(using: .hexadecimal)?.encodeClaimableBalanceId())
        XCTAssertTrue(claimableBalanceId.isValidClaimableBalanceId())
        XCTAssertFalse("BBAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU".isValidClaimableBalanceId())
        
        // type (discriminant) is missing
        asHex = "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"
        let strKey = try asHex.encodeClaimableBalanceIdHex()
        XCTAssertEqual(claimableBalanceId, strKey)
    }
    
    // MARK: - Error Cases

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
    
    // MARK: - SHA256 Hash Tests

    func testIsValidSha256Hash() throws {
        // Generate a valid SHA256 hash address (X...)
        let publicKeyData = Data(keyPair.publicKey.bytes)
        let sha256HashStrKey = try publicKeyData.encodeSha256Hash()

        // Valid SHA256 hash should return true
        XCTAssertTrue(sha256HashStrKey.isValidSha256Hash())
        XCTAssertTrue(sha256HashStrKey.hasPrefix("X"))

        // Verify the decode/encode round-trip works
        let decoded = try sha256HashStrKey.decodeSha256Hash()
        XCTAssertEqual(decoded, publicKeyData)

        // Invalid checksum should return false
        let invalidChecksum = String(sha256HashStrKey.dropLast()) + "A"
        XCTAssertFalse(invalidChecksum.isValidSha256Hash())

        // Wrong version byte (preAuthTx T-address) should return false for isValidSha256Hash
        let preAuthTxStrKey = try publicKeyData.encodePreAuthTx()
        XCTAssertFalse(preAuthTxStrKey.isValidSha256Hash())
        XCTAssertTrue(preAuthTxStrKey.hasPrefix("T"))

        // Wrong version byte (G-address) should return false
        XCTAssertFalse(accountIdEncoded.isValidSha256Hash())

        // Invalid length should return false
        XCTAssertFalse("XAAAAAA".isValidSha256Hash())

        // Empty string should return false
        XCTAssertFalse("".isValidSha256Hash())
    }

    // MARK: - PreAuthTx Tests

    func testIsValidPreAuthTx() throws {
        // Generate a valid PreAuthTx address (T...)
        let publicKeyData = Data(keyPair.publicKey.bytes)
        let preAuthTxStrKey = try publicKeyData.encodePreAuthTx()

        // Valid PreAuthTx should return true
        XCTAssertTrue(preAuthTxStrKey.isValidPreAuthTx())
        XCTAssertTrue(preAuthTxStrKey.hasPrefix("T"))

        // Verify the decode/encode round-trip works
        let decoded = try preAuthTxStrKey.decodePreAuthTx()
        XCTAssertEqual(decoded, publicKeyData)

        // Invalid checksum should return false
        let invalidChecksum = String(preAuthTxStrKey.dropLast()) + "B"
        XCTAssertFalse(invalidChecksum.isValidPreAuthTx())

        // Wrong version byte (SHA256 hash X-address) should return false for isValidPreAuthTx
        let sha256HashStrKey = try publicKeyData.encodeSha256Hash()
        XCTAssertFalse(sha256HashStrKey.isValidPreAuthTx())

        // Wrong version byte (G-address) should return false
        XCTAssertFalse(accountIdEncoded.isValidPreAuthTx())

        // Invalid length should return false
        XCTAssertFalse("TAAAA".isValidPreAuthTx())
    }

    // MARK: - Hex String Tests

    func testIsHexString() throws {
        // Valid lowercase hex
        XCTAssertTrue("0123456789abcdef".isHexString())

        // Valid uppercase hex
        XCTAssertTrue("0123456789ABCDEF".isHexString())

        // Valid mixed case hex
        XCTAssertTrue("0123456789AbCdEf".isHexString())

        // Valid hex with 0x prefix
        XCTAssertTrue("0x1234abcd".isHexString())

        // Valid 64-character hex (32 bytes)
        XCTAssertTrue("3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a".isHexString())

        // Invalid - contains non-hex characters
        XCTAssertFalse("ghijklmn".isHexString())
        XCTAssertFalse("0xZZZZ".isHexString())
        XCTAssertFalse("12345g".isHexString())

        // Invalid - odd length (hex must be even length to represent bytes)
        XCTAssertFalse("123".isHexString())
        XCTAssertFalse("abc".isHexString())

        // Empty string returns true (empty data is valid, but not useful)
        // This is the actual implementation behavior
        XCTAssertTrue("".isHexString())

        // Valid - 2-character hex
        XCTAssertTrue("ab".isHexString())
        XCTAssertTrue("00".isHexString())
        XCTAssertTrue("ff".isHexString())
    }

    // MARK: - Signed Payload Boundary Tests

    func testSignedPayloadBoundaries() throws {
        let accountId = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
        let pk = try PublicKey(accountId: accountId)

        // Test 4-byte payload (minimum valid)
        let minPayload = Data([0x01, 0x02, 0x03, 0x04])
        let minPayloadSigner = Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: minPayload)
        let minEncoded = try minPayloadSigner.encodeSignedPayload()
        XCTAssertTrue(minEncoded.isValidSignedPayload())
        let minDecoded = try minEncoded.decodeSignedPayload()
        XCTAssertEqual(minDecoded.payload, minPayload)

        // Test 64-byte payload (maximum valid)
        var maxPayloadBytes = [UInt8]()
        for i in 0..<64 {
            maxPayloadBytes.append(UInt8(i % 256))
        }
        let maxPayload = Data(maxPayloadBytes)
        let maxPayloadSigner = Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: maxPayload)
        let maxEncoded = try maxPayloadSigner.encodeSignedPayload()
        XCTAssertTrue(maxEncoded.isValidSignedPayload())
        let maxDecoded = try maxEncoded.decodeSignedPayload()
        XCTAssertEqual(maxDecoded.payload, maxPayload)

        // Test 65-byte payload (too long, should fail)
        var tooLongPayloadBytes = [UInt8]()
        for i in 0..<65 {
            tooLongPayloadBytes.append(UInt8(i % 256))
        }
        let tooLongPayload = Data(tooLongPayloadBytes)
        XCTAssertThrowsError(try Signer.signedPayload(accountId: accountId, payload: tooLongPayload))

        // Test 0-byte payload (too short, should fail or encode as invalid)
        let emptyPayload = Data()
        let emptyPayloadSigner = Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: emptyPayload)
        // Encoding an empty payload may work but validation should reject it
        let emptyEncoded = try emptyPayloadSigner.encodeSignedPayload()
        XCTAssertFalse(emptyEncoded.isValidSignedPayload())
    }

    // MARK: - Hex Conversion Function Tests

    func testHexConversionFunctions() throws {
        // Test encodeContractIdHex with valid hex
        let contractHex = "363eaa3867841fbad0f4ed88c779e4fe66e56a2470dc98c0ec9c073d05c7b103"
        let contractStrKey = try contractHex.encodeContractIdHex()
        XCTAssertEqual(contractStrKey, "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE")
        XCTAssertTrue(contractStrKey.isValidContractId())

        // Test encodeContractIdHex with invalid hex characters
        XCTAssertThrowsError(try "ZZZZ".encodeContractIdHex())
        XCTAssertThrowsError(try "123".encodeContractIdHex()) // Odd length

        // Note: Empty string does not throw - it produces an invalid but encodable result
        // The encoding succeeds but the result is not a valid contract ID
        let emptyEncoded = try "".encodeContractIdHex()
        XCTAssertFalse(emptyEncoded.isValidContractId())

        // Test encodeLiquidityPoolIdHex with valid hex
        let liquidityPoolHex = "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"
        let liquidityPoolStrKey = try liquidityPoolHex.encodeLiquidityPoolIdHex()
        XCTAssertEqual(liquidityPoolStrKey, "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN")
        XCTAssertTrue(liquidityPoolStrKey.isValidLiquidityPoolId())

        // Test encodeLiquidityPoolIdHex with invalid hex
        XCTAssertThrowsError(try "not-hex".encodeLiquidityPoolIdHex())
        XCTAssertThrowsError(try "ghijkl".encodeLiquidityPoolIdHex())

        // Test encodeClaimableBalanceIdHex with valid hex (with type discriminant missing)
        let claimableBalanceHex = "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"
        let claimableBalanceStrKey = try claimableBalanceHex.encodeClaimableBalanceIdHex()
        XCTAssertEqual(claimableBalanceStrKey, "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU")
        XCTAssertTrue(claimableBalanceStrKey.isValidClaimableBalanceId())

        // Test encodeClaimableBalanceIdHex with invalid hex
        XCTAssertThrowsError(try "xyz123".encodeClaimableBalanceIdHex())
    }

    // MARK: - Muxed Account Boundary Tests

    func testMuxedAccountBoundaries() throws {
        let accountId = "GBJRYVWMCM4IYZDEB7AUB7Q4IY64HLLWD5A3ZLONHDEDZ66YSU4IXS5N"
        let pk = try PublicKey(accountId: accountId)
        let pkBytes = pk.bytes

        // Test muxed ID = 0 (minimum)
        let muxedZero = MuxedAccountMed25519XDR(id: 0, sourceAccountEd25519: pkBytes)
        let muxXdr = MuxedAccountXDR.med25519(muxedZero)
        var muxEncoded = try XDREncoder.encode(muxXdr)
        let muxData = Data(bytes: &muxEncoded, count: muxEncoded.count)
        let muxZeroId = try muxData.encodeMuxedAccount()
        XCTAssertTrue(muxZeroId.hasPrefix("M"))
        let decodedZero = try muxZeroId.decodeMuxedAccount()
        if case .med25519(let med) = decodedZero {
            XCTAssertEqual(med.id, 0)
        } else {
            XCTFail("Expected med25519 muxed account")
        }

        // Test muxed ID = UInt64.max (maximum)
        let muxedMax = MuxedAccountMed25519XDR(id: UInt64.max, sourceAccountEd25519: pkBytes)
        let muxMaxXdr = MuxedAccountXDR.med25519(muxedMax)
        var muxMaxEncoded = try XDREncoder.encode(muxMaxXdr)
        let muxMaxData = Data(bytes: &muxMaxEncoded, count: muxMaxEncoded.count)
        let muxMaxId = try muxMaxData.encodeMuxedAccount()
        XCTAssertTrue(muxMaxId.hasPrefix("M"))
        let decodedMax = try muxMaxId.decodeMuxedAccount()
        if case .med25519(let med) = decodedMax {
            XCTAssertEqual(med.id, UInt64.max)
        } else {
            XCTFail("Expected med25519 muxed account")
        }

        // Test muxed ID validation
        XCTAssertTrue(muxZeroId.isValidMed25519PublicKey())
        XCTAssertTrue(muxMaxId.isValidMed25519PublicKey())
    }

    // MARK: - Contract ID Additional Tests

    func testContractIdValidation() throws {
        // Valid contract ID
        XCTAssertTrue("CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE".isValidContractId())

        // Wrong prefix (G instead of C)
        XCTAssertFalse("GA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE".isValidContractId())

        // Invalid checksum
        XCTAssertFalse("CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXX".isValidContractId())

        // Wrong length
        XCTAssertFalse("CA3D5KRYM6CB".isValidContractId())
        XCTAssertFalse("".isValidContractId())
    }

    // MARK: - Liquidity Pool ID Additional Tests

    func testLiquidityPoolIdValidation() throws {
        // Valid liquidity pool ID
        XCTAssertTrue("LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN".isValidLiquidityPoolId())

        // Wrong prefix
        XCTAssertFalse("GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN".isValidLiquidityPoolId())

        // Invalid checksum
        XCTAssertFalse("LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJX".isValidLiquidityPoolId())

        // Wrong length
        XCTAssertFalse("LA7QYNF7".isValidLiquidityPoolId())
    }

    // MARK: - Claimable Balance ID Additional Tests

    func testClaimableBalanceIdValidation() throws {
        // Valid claimable balance ID
        XCTAssertTrue("BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU".isValidClaimableBalanceId())

        // Wrong prefix
        XCTAssertFalse("GAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU".isValidClaimableBalanceId())

        // Invalid checksum
        XCTAssertFalse("BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TX".isValidClaimableBalanceId())

        // Wrong length
        XCTAssertFalse("BAAD6DBUX6".isValidClaimableBalanceId())
    }

    // MARK: - Error Type Tests

    func testKeyUtilsErrorTypes() throws {
        // Test invalidEncodedString error
        do {
            _ = try "GBPXX0A5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL".decodeEd25519PublicKey()
            XCTFail("Expected error")
        } catch KeyUtilsError.invalidEncodedString {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        // Test invalidVersionByte error
        do {
            _ = try "SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36XCU".decodeEd25519PublicKey()
            XCTFail("Expected error")
        } catch KeyUtilsError.invalidVersionByte {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        // Test invalidChecksum error
        do {
            _ = try "GBPXXOA5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVT".decodeEd25519PublicKey()
            XCTFail("Expected error")
        } catch KeyUtilsError.invalidChecksum {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Regression Tests

    func testIssue172() throws {
        let xdr = "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"
        
        let tx = try Transaction(envelopeXdr: xdr)
        let op = tx.operations.first!
        guard let invokeHostFunctionOp = op as? InvokeHostFunctionOperation else {
            XCTFail("not invoke host function op")
            return
        }
        switch invokeHostFunctionOp.hostFunction {
        case .invokeContract(let args):
            let address = args.contractAddress
            
            guard let bid = address.claimableBalanceId else {
                XCTFail("not claimable balance address")
                return
            }

            let strKey = try bid.encodeClaimableBalanceIdHex()
            XCTAssertEqual("BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU", strKey)

            guard let strKey2 = try address.getClaimableBalanceIdStrKey() else {
                XCTFail("not claimable balance address")
                return
            }
            XCTAssertEqual("BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU", strKey2)


            switch address {
            case .claimableBalanceId(let claimableBalanceIDXDR):
                switch claimableBalanceIDXDR {
                case .claimableBalanceIDTypeV0(let wrappedData32):
                    let strKey = try wrappedData32.wrapped.encodeClaimableBalanceId()
                    XCTAssertEqual("BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU", strKey)
                }
            default:
                XCTFail("not claimable balance address")
            }
            
            // test decoding
            let newAddress = try SCAddressXDR(claimableBalanceId: strKey)
            XCTAssertEqual(bid, newAddress.claimableBalanceId)
            
            let hext = try strKey.decodeClaimableBalanceIdToHex()
            XCTAssertEqual(bid, hext)
        default:
            XCTFail("not invoke contract host function")
            
        }
    }
}
