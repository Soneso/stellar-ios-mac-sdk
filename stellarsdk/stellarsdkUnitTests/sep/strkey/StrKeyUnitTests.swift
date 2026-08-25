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

    /// Well formed strkey encoded ed25519 public keys.
    let validAccountIds = [
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

    /// The first entry of validAccountIds with its last base-32 character changed. That
    /// character only carries checksum bits, so the string stays canonical base-32 of the
    /// same length and still holds the ed25519 public key version byte and the same 32 key
    /// bytes. Only the CRC-16 checksum no longer matches.
    let corruptedChecksumAccountId = "GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBC"

    /// Well formed strkey encoded ed25519 secret seeds, each paired with the account id
    /// the keypair derived from it carries.
    let validSecretSeeds: [(secret: String, accountId: String)] = [
        ("SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY",
         "GBKHPLNGLNIWZNYM3RTIBUGBJAQD62AAURRYMFJDYK2VCUWHLUMUPV2F"),
        ("SCZTUEKSEH2VYZQC6VLOTOM4ZDLMAGV4LUMH4AASZ4ORF27V2X64F2S2",
         "GBOFPETTCLIHTS5NBNMEHFF53GIMRBMM4JI3SPEGWQZTPPH6Y4WKKZBC"),
        ("SCGNLQKTZ4XCDUGVIADRVOD4DEVNYZ5A7PGLIIZQGH7QEHK6DYODTFEH",
         "GDVQONOI57O462IAWZUET5IIRIQI2EA6HARUETPONZXQLH6US3TVSU2M"),
        ("SDH6R7PMU4WIUEXSM66LFE4JCUHGYRTLTOXVUV5GUEPITQEO3INRLHER",
         "GAIANYR43247AG4HFMQM6GIS4NYDUO7OP6C5KLTQLXUZZCUD6S4TETQX"),
        ("SC2RDTRNSHXJNCWEUVO7VGUSPNRAWFCQDPP6BGN4JFMWDSEZBRAPANYW",
         "GAVHFB2F26FE2JT2LTWX5EDFHQ4FJBXSG37IY43PP54O3TZXDWQFM6Y6"),
        ("SCEMFYOSFZ5MUXDKTLZ2GC5RTOJO6FGTAJCF3CCPZXSLXA2GX6QUYOA7",
         "GDAEQY7DSRCWGFCQTYVPZ7Y6JDCOLJ7BA7T6GXCJPKJBIPWGN426D3ME")
    ]

    /// The first entry of validSecretSeeds with its last base-32 character changed. That
    /// character only carries checksum bits, so the string stays canonical base-32 of the
    /// same length and still holds the ed25519 secret seed version byte and the same 32 seed
    /// bytes. Only the CRC-16 checksum no longer matches.
    let corruptedChecksumSecretSeed = "SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDZ"

    /// Well formed strkey encoded muxed account address: the ed25519 public key of
    /// GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ multiplexed with the
    /// id 9223372036854775808.
    let muxedAccountId = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"

    /// The muxed account address above with its last base-32 character changed. That character
    /// only carries checksum bits, so the string stays canonical base-32 of the same length and
    /// still holds the med25519 public key version byte, the same 32 key bytes and the same
    /// id. Only the CRC-16 checksum no longer matches.
    let corruptedChecksumMuxedAccountId = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLM"

    /// Canonical base-32 carrying the ed25519 public key version byte, a 31 byte payload and
    /// the CRC-16 checksum that payload produces, encoded in 55 characters. An ed25519 public
    /// key is 32 bytes, so the encoded length its version byte allows is the only check this
    /// fails.
    let wrongPayloadWidthAccountId = "GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAG4XI"

    /// Canonical base-32 carrying the med25519 public key version byte, a 45 byte payload and
    /// the CRC-16 checksum that payload produces, encoded in 77 characters. A muxed account
    /// address is a 32 byte ed25519 public key followed by an 8 byte id, so the encoded length
    /// its version byte allows is the only check this fails.
    let wrongPayloadWidthMuxedAccountId = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAAAAAAAAAAADE4"

    /// Canonical base-32 carrying the contract version byte, a 33 byte payload and the CRC-16
    /// checksum that payload produces, encoded in 58 characters. A contract id is 32 bytes.
    let wrongPayloadWidthContractId = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADZKM"

    /// Canonical base-32 carrying the claimable balance version byte, a 32 byte payload and
    /// the CRC-16 checksum that payload produces, encoded in 56 characters. A claimable
    /// balance id is a one byte type discriminant followed by a 32 byte hash.
    let wrongPayloadWidthClaimableBalanceId = "BAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZBO"

    /// The claimable balance strkey SEP-23 lists as invalid. It is canonical base-32, is
    /// encoded in the 58 characters the claimable balance version byte allows, carries that
    /// version byte and holds the CRC-16 checksum matching its body. Its body is the 33 bytes
    /// a claimable balance id is wide and holds the same 32 byte id as the well formed one
    /// used throughout these tests. Only its leading type discriminant is wrong: it reads 1,
    /// and CLAIMABLE_BALANCE_ID_TYPE_V0 is the only type the XDR union defines.
    let sep23InvalidClaimableBalanceType = "BAAT6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGXACA"

    /// The signed payload strkeys SEP-23 lists as invalid. Each is canonical base-32, is
    /// encoded in a length the signed payload version byte allows, carries that version byte
    /// and holds the CRC-16 checksum matching its body. Only the framing of the body is
    /// wrong. A signed payload body is the 32 byte signer key, the length of the signed data
    /// as a 4 byte big endian integer, the signed data itself and zero padding to a multiple
    /// of four bytes, so a body whose length field reads n is 36 + n rounded up to a multiple
    /// of four bytes wide.
    let sep23InvalidSignedPayloads: [(strKey: String, reason: String)] = [
        // length field 32, body 72 bytes where that length field allows 68
        ("PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAQACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IAAAAAAAAPM",
         "length prefix shorter than payload"),
        // length field 29, body 64 bytes where that length field allows 68
        ("PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4Z2PQ",
         "length prefix longer than payload"),
        // length field 29, body 65 bytes where that length field allows 68
        ("PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DXFH6",
         "no zero padding")
    ]

    /// Signed payload strkeys built like the SEP-23 ones above, over the signer key of
    /// GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ, covering the shapes the
    /// specification's own vectors do not reach: a broken body at either end of the encoded
    /// length range, and padding that is not zero bytes.
    let malformedFramingSignedPayloads: [(strKey: String, reason: String)] = [
        // length field 0, body 40 bytes where that length field allows 36. It is also the
        // shortest strkey the signed payload version byte accepts.
        ("PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAABO6A",
         "length field zero, at the shortest encoded length"),
        // length field 65, body 100 bytes where that length field allows 104. It is also the
        // longest strkey the signed payload version byte accepts.
        ("PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAABAQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IBBEIRSIJJGE4UCSKRLFQWS4LZQGEZDGNBVGY3TQOJ2HM6D2PR7ICJ4E",
         "length field one over the maximum, at the longest encoded length"),
        // length field 29, body 68 bytes as that length field requires, last padding byte 0x01
        ("PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUAAAAMHDU",
         "padding byte not zero")
    ]

    /// The strkey the signed payload body carrying signed data one byte over the maximum
    /// encodes to: the signer key of GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ,
    /// a length field reading 65, 65 bytes of signed data and the three zero padding bytes
    /// that width takes to a multiple of four. The body is 104 bytes, exactly the width its
    /// length field names, and its padding is zero, so the length bound is the only framing
    /// rule it breaks. At 172 characters the string is longer than the 165 the signed payload
    /// version byte allows, so no decoder reads it back.
    let oversizedSignedPayload = "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAABAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQAAAAOU3A"

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
        
        // throws invalidVersionByte when the strkey carries a version byte other than the one
        // the decoder it is handed to stands for
        let wrongVersionByte: [(String, (String) throws -> Any)] = [
            ("GBPXXOA5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL", { try $0.decodeEd25519SecretSeed() }),
            ("SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36XCU", { try $0.decodeEd25519PublicKey() })
        ]
        for (input, decode) in wrongVersionByte {
            do {
                _ = try decode(input)
                XCTFail("Expected error for \"\(input)\"")
            } catch KeyUtilsError.invalidVersionByte {
                // Expected
            } catch {
                XCTFail("Unexpected error type for \"\(input)\": \(error)")
            }
        }

        // throws invalidEncodedString when the strkey holds a character the base32 alphabet
        // does not have, or is not one of the encoded lengths its version byte allows
        let notWellFormed: [(String, (String) throws -> Any)] = [
            ("GBPXX0A5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL", { try $0.decodeEd25519PublicKey() }),
            // 58 characters where the ed25519 public key version byte allows exactly 56, so
            // the encoded length rejects it before its '+' characters are read
            ("GCFZB6L25D26RQFDWSSBDEYQ32JHLRMTT44ZYE3DZQUTYOL7WY43PLBG++", { try $0.decodeEd25519PublicKey() }),
            ("GB6OWYST45X57HCJY5XWOHDEBULB6XUROWPIKW77L5DSNANBEQGUPADT2T", { try $0.decodeEd25519PublicKey() }),
            ("SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYW", { try $0.decodeEd25519SecretSeed() }),
            ("SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYWMEGB2W2", { try $0.decodeEd25519SecretSeed() }),
            ("SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYWMEGB2W2T", { try $0.decodeEd25519SecretSeed() }),
            ("SCMB30FQCIQAWZ4WQTS6SVK37LGMAFJGXOZIHTH2PY6EXLP37G46H6DT", { try $0.decodeEd25519SecretSeed() }),
            // 58 characters where the ed25519 secret seed version byte allows exactly 56, so
            // the encoded length rejects it before its '+' characters are read
            ("SAYC2LQ322EEHZYWNSKBEW6N66IRTDREEBUXXU5HPVZGMAXKLIZNM45H++", { try $0.decodeEd25519SecretSeed() }),
            // canonical base-32 holding the checksum matching its body, in 13 and in 58
            // characters where the ed25519 public key version byte allows exactly 56
            ("GAAAAAAAACGC6", { try $0.decodeEd25519PublicKey() }),
            ("GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUACUSI", { try $0.decodeEd25519PublicKey() }),
            (oversizedSignedPayload, { try $0.decodeSignedPayload() })
        ]
        for (input, decode) in notWellFormed {
            do {
                _ = try decode(input)
                XCTFail("Expected error for \"\(input)\"")
            } catch KeyUtilsError.invalidEncodedString {
                // Expected
            } catch {
                XCTFail("Unexpected error type for \"\(input)\": \(error)")
            }
        }

        // throws invalidChecksum when the CRC-16 does not match the payload
        let wrongChecksum: [(String, (String) throws -> Any)] = [
            ("GBPXXOA5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVT", { try $0.decodeEd25519PublicKey() }),
            ("SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36XCX", { try $0.decodeEd25519SecretSeed() })
        ]
        for (input, decode) in wrongChecksum {
            do {
                _ = try decode(input)
                XCTFail("Expected error for \"\(input)\"")
            } catch KeyUtilsError.invalidChecksum {
                // Expected
            } catch {
                XCTFail("Unexpected error type for \"\(input)\": \(error)")
            }
        }

        // throws invalidEncodedString for strkeys shorter than any encoded length their
        // version byte allows, down to the empty string
        let truncated: [(String, (String) throws -> Any)] = [
            ("", { try $0.decodeEd25519PublicKey() }),
            ("GA", { try $0.decodeEd25519PublicKey() }),
            ("GAAA", { try $0.decodeEd25519PublicKey() }),
            ("GAAAA", { try $0.decodeEd25519PublicKey() }),
            ("SA", { try $0.decodeEd25519SecretSeed() }),
            ("MA", { try $0.decodeMed25519PublicKey() }),
            ("TA", { try $0.decodePreAuthTx() }),
            ("XA", { try $0.decodeSha256Hash() }),
            ("PA", { try $0.decodeSignedPayload() }),
            ("CA", { try $0.decodeContractId() }),
            ("LA", { try $0.decodeLiquidityPoolId() }),
            ("BA", { try $0.decodeClaimableBalanceId() })
        ]
        for (input, decode) in truncated {
            do {
                _ = try decode(input)
                XCTFail("Expected error for \"\(input)\"")
            } catch KeyUtilsError.invalidEncodedString {
                // Expected
            } catch {
                XCTFail("Unexpected error type for \"\(input)\": \(error)")
            }
        }

        // rejects an encoded string one character shorter or one character longer than the
        // lengths the version byte allows, while the bounds themselves still decode. Every
        // type but the signed payload has a single valid length, so its lower and upper
        // bound are the same string.
        let publicKeyData = Data(keyPair.publicKey.bytes)
        let preAuthTx = try publicKeyData.encodePreAuthTx()
        let sha256Hash = try publicKeyData.encodeSha256Hash()
        let contractId = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"
        let liquidityPoolId = "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN"
        let claimableBalanceId = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU"
        let signerKey = try PublicKey(accountId: validAccountIds[0]).wrappedData32()
        // one byte is the shortest signed data a signed payload may carry, and 64 bytes the
        // longest, so these are the shortest and the longest strkey its version byte allows
        let shortestSignedPayload = try Ed25519SignedPayload(
            ed25519: signerKey,
            payload: Data([0x01])).encodeSignedPayload()
        let longestSignedPayload = try Ed25519SignedPayload(
            ed25519: signerKey,
            payload: Data(repeating: 0x01, count: StellarProtocolConstants.SIGNED_PAYLOAD_MAX_PAYLOAD)).encodeSignedPayload()
        let lengthBounds: [(lower: String, upper: String, decode: (String) throws -> Any, isValid: (String) -> Bool)] = [
            (validAccountIds[0], validAccountIds[0], { try $0.decodeEd25519PublicKey() }, { $0.isValidEd25519PublicKey() }),
            (validSecretSeeds[0].secret, validSecretSeeds[0].secret, { try $0.decodeEd25519SecretSeed() }, { $0.isValidEd25519SecretSeed() }),
            (muxedAccountId, muxedAccountId, { try $0.decodeMed25519PublicKey() }, { $0.isValidMed25519PublicKey() }),
            (preAuthTx, preAuthTx, { try $0.decodePreAuthTx() }, { $0.isValidPreAuthTx() }),
            (sha256Hash, sha256Hash, { try $0.decodeSha256Hash() }, { $0.isValidSha256Hash() }),
            (contractId, contractId, { try $0.decodeContractId() }, { $0.isValidContractId() }),
            (liquidityPoolId, liquidityPoolId, { try $0.decodeLiquidityPoolId() }, { $0.isValidLiquidityPoolId() }),
            (claimableBalanceId, claimableBalanceId, { try $0.decodeClaimableBalanceId() }, { $0.isValidClaimableBalanceId() }),
            (shortestSignedPayload, longestSignedPayload, { try $0.decodeSignedPayload() }, { $0.isValidSignedPayload() })
        ]
        for (lower, upper, decode, isValid) in lengthBounds {
            XCTAssertNoThrow(try decode(lower), "Expected \"\(lower)\" to decode")
            XCTAssertNoThrow(try decode(upper), "Expected \"\(upper)\" to decode")
            XCTAssertTrue(isValid(lower), "Expected \"\(lower)\" to be valid")
            XCTAssertTrue(isValid(upper), "Expected \"\(upper)\" to be valid")

            for outOfRange in [String(lower.dropLast()), upper + "A"] {
                do {
                    _ = try decode(outOfRange)
                    XCTFail("Expected error for \"\(outOfRange)\"")
                } catch KeyUtilsError.invalidEncodedString {
                    // Expected
                } catch {
                    XCTFail("Unexpected error type for \"\(outOfRange)\": \(error)")
                }
                XCTAssertFalse(isValid(outOfRange), "Expected \"\(outOfRange)\" to be invalid")
            }
        }

        // rejects a strkey that is canonical base32, carries the version byte its decoder
        // expects and holds the checksum matching its payload, but whose payload is not the
        // width that version byte stands for
        let wrongPayloadWidth: [(String, (String) throws -> Any, (String) -> Bool)] = [
            (wrongPayloadWidthAccountId, { try $0.decodeEd25519PublicKey() }, { $0.isValidEd25519PublicKey() }),
            (wrongPayloadWidthMuxedAccountId, { try $0.decodeMed25519PublicKey() }, { $0.isValidMed25519PublicKey() }),
            (wrongPayloadWidthContractId, { try $0.decodeContractId() }, { $0.isValidContractId() }),
            (wrongPayloadWidthClaimableBalanceId, { try $0.decodeClaimableBalanceId() }, { $0.isValidClaimableBalanceId() })
        ]
        for (input, decode, isValid) in wrongPayloadWidth {
            do {
                _ = try decode(input)
                XCTFail("Expected error for \"\(input)\"")
            } catch KeyUtilsError.invalidEncodedString {
                // Expected
            } catch {
                XCTFail("Unexpected error type for \"\(input)\": \(error)")
            }
            XCTAssertFalse(isValid(input), "Expected \"\(input)\" to be invalid")
        }
        do {
            _ = try PublicKey(accountId: wrongPayloadWidthAccountId)
            XCTFail("Expected error for \"\(wrongPayloadWidthAccountId)\"")
        } catch Ed25519Error.invalidPublicKey {
            // Expected
        } catch {
            XCTFail("Unexpected error type for \"\(wrongPayloadWidthAccountId)\": \(error)")
        }

        do {
            _ = try KeyPair(accountId: wrongPayloadWidthAccountId)
            XCTFail("Expected error for \"\(wrongPayloadWidthAccountId)\"")
        } catch Ed25519Error.invalidPublicKey {
            // Expected
        } catch {
            XCTFail("Unexpected error type for \"\(wrongPayloadWidthAccountId)\": \(error)")
        }

        // a well formed claimable balance id decodes to the type discriminant
        // CLAIMABLE_BALANCE_ID_TYPE_V0 followed by the 32 byte id, on both decoding paths
        let claimableBalanceIdHex = "003f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"
        let decodedClaimableBalanceId = try claimableBalanceId.decodeClaimableBalanceId()
        XCTAssertEqual(decodedClaimableBalanceId.count,
                       StellarProtocolConstants.CLAIMABLE_BALANCE_DISCRIMINANT_SIZE + StellarProtocolConstants.STRKEY_DECODED_SIZE_STANDARD)
        XCTAssertEqual(decodedClaimableBalanceId.first, UInt8(ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue))
        XCTAssertEqual(decodedClaimableBalanceId.base16EncodedString(), claimableBalanceIdHex)
        XCTAssertEqual(try claimableBalanceId.decodeClaimableBalanceIdToHex(), claimableBalanceIdHex)

        // every well formed account id decodes to the same key bytes through the strkey
        // decoder, through PublicKey and through KeyPair, and re-encodes to the input
        for accountId in validAccountIds {
            let expected = try accountId.decodeEd25519PublicKey()
            let publicKey = try PublicKey(accountId: accountId)
            XCTAssertEqual(Data(publicKey.bytes), expected)
            XCTAssertEqual(publicKey.accountId, accountId)
            XCTAssertEqual(Data(try KeyPair(accountId: accountId).publicKey.bytes), expected)
        }
        let encodedPublicKey = try PublicKey(accountId: accountIdEncoded)
        XCTAssertEqual(encodedPublicKey.bytes, keyPair.publicKey.bytes)
        XCTAssertEqual(encodedPublicKey.accountId, accountIdEncoded)

        // every well formed secret seed decodes to the same seed bytes through the strkey
        // decoder and through Seed, re-encodes to the input, and derives its account id
        for (secret, accountId) in validSecretSeeds {
            let expected = try secret.decodeEd25519SecretSeed()
            let seed = try Seed(secret: secret)
            XCTAssertEqual(Data(seed.bytes), expected)
            XCTAssertEqual(seed.secret, secret)
            XCTAssertEqual(KeyPair(seed: seed).accountId, accountId)
            let importedKeyPair = try KeyPair(secretSeed: secret)
            XCTAssertEqual(Data(importedKeyPair.seed!.bytes), expected)
            XCTAssertEqual(importedKeyPair.accountId, accountId)
            XCTAssertEqual(importedKeyPair.secretSeed, secret)
        }
        let encodedSeed = try Seed(secret: seedEncoded)
        XCTAssertEqual(encodedSeed.bytes, keyPair.seed!.bytes)
        XCTAssertEqual(encodedSeed.secret, seedEncoded)
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

        // encodes the one payload width its version byte stands for, and refuses any other
        // width instead of emitting a strkey the decoder would reject
        let standardSize = StellarProtocolConstants.STRKEY_DECODED_SIZE_STANDARD
        let muxedSize = StellarProtocolConstants.STRKEY_DECODED_SIZE_MUXED
        let fixedWidth: [(name: String, size: Int, encode: (Data) throws -> String, decode: (String) throws -> Data)] = [
            ("ed25519 public key", standardSize, { try $0.encodeEd25519PublicKey() }, { try $0.decodeEd25519PublicKey() }),
            ("ed25519 secret seed", standardSize, { try $0.encodeEd25519SecretSeed() }, { try $0.decodeEd25519SecretSeed() }),
            ("pre authorized transaction hash", standardSize, { try $0.encodePreAuthTx() }, { try $0.decodePreAuthTx() }),
            ("sha256 hash", standardSize, { try $0.encodeSha256Hash() }, { try $0.decodeSha256Hash() }),
            ("contract id", standardSize, { try $0.encodeContractId() }, { try $0.decodeContractId() }),
            ("liquidity pool id", standardSize, { try $0.encodeLiquidityPoolId() }, { try $0.decodeLiquidityPoolId() }),
            ("med25519 public key", muxedSize, { try $0.encodeMEd25519AccountId() }, { try $0.decodeMed25519PublicKey() })
        ]
        for (name, size, encode, decode) in fixedWidth {
            let payload = Data((0..<size).map { UInt8($0) })
            let encoded = try encode(payload)
            XCTAssertEqual(try decode(encoded), payload, "Expected \(name) of \(size) bytes to round trip")

            for wrongSize in [0, size - 1, size + 1] {
                do {
                    _ = try encode(Data(repeating: 0x01, count: wrongSize))
                    XCTFail("Expected error for \(name) of \(wrongSize) bytes")
                } catch StellarSDKError.invalidArgument {
                    // Expected
                } catch {
                    XCTFail("Unexpected error type for \(name) of \(wrongSize) bytes: \(error)")
                }
            }
        }

        // a claimable balance id encodes from the id on its own, in which case the type
        // discriminant is put in front of it, and from the body that already carries it
        let typeV0 = UInt8(ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)
        let balanceId = Data((0..<StellarProtocolConstants.CLAIMABLE_BALANCE_ID_SIZE).map { UInt8($0) })
        let balanceBody = Data([typeV0]) + balanceId
        let encodedFromId = try balanceId.encodeClaimableBalanceId()
        XCTAssertEqual(encodedFromId, try balanceBody.encodeClaimableBalanceId())
        XCTAssertTrue(encodedFromId.isValidClaimableBalanceId())
        XCTAssertEqual(try encodedFromId.decodeClaimableBalanceId(), balanceBody)

        // refuses a body opening with a type the XDR union does not define, and any width
        // that is neither the id on its own nor the body
        let invalidBalanceIds: [(data: Data, reason: String)] = [
            (Data([0x01]) + balanceId, "type the XDR union does not define"),
            (Data(), "no data at all"),
            (balanceId.dropLast(), "one byte short of the id"),
            (balanceBody + Data([0x00]), "one byte over the body")
        ]
        for (data, reason) in invalidBalanceIds {
            do {
                _ = try data.encodeClaimableBalanceId()
                XCTFail("Expected error for \(reason)")
            } catch StellarSDKError.invalidArgument {
                // Expected
            } catch {
                XCTFail("Unexpected error type for \(reason): \(error)")
            }
        }
    }

    func testIsValid() throws {
        // returns true for valid public key
        var keys = validAccountIds

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
            validSecretSeeds[0].secret,
            "gWRYUerEKuz53tstxEuR3NCkiQDcV4wzFHmvLnZmj7PUqxW2wt",
            "test",
            "g4VPBPrHZkfE8CsjuG2S4yBQNd455UWmk", // Old network key
            wrongPayloadWidthAccountId
          ]
        
        for key in keys {
            XCTAssertFalse(key.isValidEd25519PublicKey())
        }
        
        // returns true for valid secret key
        keys = validSecretSeeds.map { $0.secret }

        for key in keys {
            XCTAssertTrue(key.isValidEd25519SecretSeed())
            XCTAssertNoThrow(try Seed(secret: key))
        }

        // returns false for invalid secret key
        keys = [
              validAccountIds[0],
              "SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDYT", // Too long
              "SAFGAMN5Z6IHVI3IVEPIILS7ITZDYSCEPLN4FN5Z3IY63DRH4CIYEV", // To short
              "SAFGAMN5Z6IHVI3IVEPIILS7ITZDYSCEPLN4FN5Z3IY63DRH4CIYEVIT", // Checksum
              "test",
              corruptedChecksumSecretSeed,
            ]

        for key in keys {
            XCTAssertFalse(key.isValidEd25519SecretSeed())
            do {
                _ = try Seed(secret: key)
                XCTFail("Expected error for \"\(key)\"")
            } catch Ed25519Error.invalidSeed {
                // Expected
            } catch {
                XCTFail("Unexpected error type for \"\(key)\": \(error)")
            }
        }
    }
    
    // MARK: - Muxed Account Tests

    func testMuxedAccount() throws {
        let rawMPubKey =  "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a8000000000000000".data(using: .hexadecimal)!

        // encodes & decodes M... addresses correctly
        XCTAssertEqual(try rawMPubKey.encodeMEd25519AccountId(), muxedAccountId)
        XCTAssertEqual(try muxedAccountId.decodeMed25519PublicKey(), rawMPubKey)
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

    func testEncodeMuxedAccountRejectsWrongWidths() throws {
        // Exact widths per key type: 36 bytes for KEY_TYPE_ED25519, 44 for KEY_TYPE_MUXED_ED25519.
        let gAddress = "GBJRYVWMCM4IYZDEB7AUB7Q4IY64HLLWD5A3ZLONHDEDZ66YSU4IXS5N"
        let mAddress = "MAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSAAAAAAAAAAE2LP26"
        let ed25519Data = try Data(XDREncoder.encode(try gAddress.decodeMuxedAccount()))
        let muxedData = try Data(XDREncoder.encode(try mAddress.decodeMuxedAccount()))
        XCTAssertEqual(36, ed25519Data.count)
        XCTAssertEqual(44, muxedData.count)

        // Exact widths still encode.
        XCTAssertEqual(gAddress, try ed25519Data.encodeMuxedAccount())
        XCTAssertEqual(mAddress, try muxedData.encodeMuxedAccount())

        // Over-wide ed25519 data was previously accepted with the extra bytes silently ignored.
        XCTAssertThrowsError(try (ed25519Data + Data([0x00])).encodeMuxedAccount()) { error in
            guard case StellarSDKError.invalidArgument(let message) = error else {
                return XCTFail("expected invalidArgument, got \(error)")
            }
            XCTAssertEqual("invalid ed25519 muxed account length 37, must be 36 bytes", message)
        }
        XCTAssertThrowsError(try (ed25519Data + Data(repeating: 0xab, count: 8)).encodeMuxedAccount()) { error in
            guard case StellarSDKError.invalidArgument = error else {
                return XCTFail("expected invalidArgument, got \(error)")
            }
        }

        // Over-wide med25519 data.
        XCTAssertThrowsError(try (muxedData + Data([0x00])).encodeMuxedAccount()) { error in
            guard case StellarSDKError.invalidArgument(let message) = error else {
                return XCTFail("expected invalidArgument, got \(error)")
            }
            XCTAssertEqual("invalid med25519 muxed account length 45, must be 44 bytes", message)
        }

        // Under-wide data previously surfaced a decoder error; it is invalidArgument now.
        XCTAssertThrowsError(try ed25519Data.prefix(35).encodeMuxedAccount()) { error in
            guard case StellarSDKError.invalidArgument(let message) = error else {
                return XCTFail("expected invalidArgument, got \(error)")
            }
            XCTAssertEqual("invalid muxed account length 35, must be 36 bytes (44 for KEY_TYPE_MUXED_ED25519)", message)
        }
        XCTAssertThrowsError(try muxedData.prefix(43).encodeMuxedAccount()) { error in
            guard case StellarSDKError.invalidArgument = error else {
                return XCTFail("expected invalidArgument, got \(error)")
            }
        }
        XCTAssertThrowsError(try Data().encodeMuxedAccount()) { error in
            guard case StellarSDKError.invalidArgument = error else {
                return XCTFail("expected invalidArgument, got \(error)")
            }
        }
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
        XCTAssertThrowsError(try Signer.signedPayload(accountId: accountId, payload: data)) { error in
            guard case StellarSDKError.invalidArgument = error else {
                return XCTFail("Unexpected error type: \(error)")
            }
        }
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

    /// The SEP-23 valid vectors for the contract address and for the muxed address
    /// multiplexing id 0.
    func testSep23ContractAndMuxedIdZeroVectors() throws {
        let contract = "CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA"
        XCTAssertTrue(contract.isValidContractId())
        XCTAssertEqual(try contract.decodeContractId().encodeContractId(), contract)

        let muxedIdZero = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ"
        XCTAssertTrue(muxedIdZero.isValidMed25519PublicKey())
        XCTAssertEqual(try muxedIdZero.decodeMed25519PublicKey().encodeMEd25519AccountId(), muxedIdZero)

        // An id of 0 stays a muxed account: it multiplexes the base account, it does not
        // collapse into it.
        let mux = try muxedIdZero.decodeMuxedAccount()
        guard case .med25519(let med) = mux else {
            return XCTFail("Expected the med25519 arm, got \(mux)")
        }
        XCTAssertEqual(med.id, 0)
        XCTAssertEqual(try Data(XDREncoder.encode(mux)).encodeMuxedAccount(), muxedIdZero)
    }

    func testInvalidStrKeys() throws {
        // The unused trailing bit must be zero in the encoding of the last three
        // bytes (24 bits) as five base-32 symbols (25 bits)
        var strKey = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUR"
        XCTAssertFalse(strKey.isValidMed25519PublicKey())
        
        // Invalid length (congruent to 1 mod 8)
        strKey = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZA"
        XCTAssertFalse(strKey.isValidEd25519PublicKey())

        // Invalid algorithm (low 3 bits of version byte are 7)
        strKey = "G47QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVP2I"
        XCTAssertFalse(strKey.isValidEd25519PublicKey())

        // Invalid length (congruent to 6 mod 8)
        strKey = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLKA"
        XCTAssertFalse(strKey.isValidMed25519PublicKey())
        
        // Invalid algorithm (low 3 bits of version byte are 7)
        strKey = "M47QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ"
        XCTAssertFalse(strKey.isValidMed25519PublicKey())
        
        // Invalid length: base-32 padding characters take it to 72 where the med25519 version
        // byte allows exactly 69
        strKey = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUK==="
        XCTAssertFalse(strKey.isValidMed25519PublicKey())
        
        // Invalid checksum
        strKey = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUO"
        XCTAssertFalse(strKey.isValidMed25519PublicKey())
        
        // Trailing bits should be zeroes
        strKey = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TV"
        XCTAssertFalse(strKey.isValidClaimableBalanceId())

        // Claimable balance type the XDR union does not define
        XCTAssertFalse(sep23InvalidClaimableBalanceType.isValidClaimableBalanceId())
        
        // Invalid length (Ed25519 should be 32 bytes, not 5)
        strKey = "GAAAAAAAACGC6"
        XCTAssertFalse(strKey.isValidEd25519PublicKey())
        
        // Invalid length (base-32 decoding should yield 35 bytes, not 36)
        strKey = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUACUSI"
        XCTAssertFalse(strKey.isValidEd25519PublicKey())
        
        // Invalid length (base-32 decoding should yield 43 bytes, not 44)
        strKey = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAAV75I"
        XCTAssertFalse(strKey.isValidMed25519PublicKey())

        // A signed payload whose body breaks the framing: the three shapes SEP-23 lists, and
        // the shapes its vectors do not reach
        for (signedPayload, reason) in sep23InvalidSignedPayloads + malformedFramingSignedPayloads {
            XCTAssertFalse(signedPayload.isValidSignedPayload(), "Expected \(reason) to be invalid")
        }

        // The strkey a body carrying signed data one byte over the maximum encodes to is
        // longer than the signed payload version byte allows
        XCTAssertFalse(oversizedSignedPayload.isValidSignedPayload())
    }

    /// A character can span several unicode scalars, so a string of the character count the
    /// version byte allows can still hold more scalars than a strkey encodes in. Every such
    /// character carries a scalar the base-32 alphabet does not have, so it is rejected.
    func testStrKeysCarryingMultiScalarCharacters() throws {
        let accountId = validAccountIds[0]
        let head = String(accountId.dropLast())
        let multiScalar: [(strKey: String, reason: String)] = [
            (String(accountId.prefix(1)) + "\u{0301}" + String(accountId.dropFirst()),
             "a combining acute accent"),
            (head + "\r\n",
             "a carriage return and line feed pair"),
            (head + "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}",
             "a zero width joiner sequence")
        ]
        for (strKey, reason) in multiScalar {
            XCTAssertEqual(strKey.count, accountId.count,
                           "Expected \(reason) to keep the character count of an account id")
            XCTAssertGreaterThan(strKey.unicodeScalars.count, accountId.unicodeScalars.count,
                                 "Expected \(reason) to add unicode scalars")
            XCTAssertFalse(strKey.isValidEd25519PublicKey(), "Expected \(reason) to be invalid")
            XCTAssertThrowsError(try strKey.decodeEd25519PublicKey(),
                                 "Expected \(reason) to be rejected") { error in
                guard case KeyUtilsError.invalidEncodedString = error else {
                    return XCTFail("Unexpected error type for \(reason): \(error)")
                }
            }
        }
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

        // Test 1-byte payload (shortest signed data the framing allows)
        let shortestPayload = Data([0x01])
        let shortestPayloadSigner = Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: shortestPayload)
        let shortestEncoded = try shortestPayloadSigner.encodeSignedPayload()
        XCTAssertTrue(shortestEncoded.isValidSignedPayload())
        let shortestDecoded = try shortestEncoded.decodeSignedPayload()
        XCTAssertEqual(shortestDecoded.payload, shortestPayload)

        // Test 4-byte payload (signed data filling the smallest width its field has)
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
        XCTAssertThrowsError(try Signer.signedPayload(accountId: accountId, payload: tooLongPayload)) { error in
            guard case StellarSDKError.invalidArgument = error else {
                return XCTFail("Unexpected error type: \(error)")
            }
        }

        // Test 0-byte payload (too short, should fail)
        let emptyPayload = Data()
        let emptyPayloadSigner = Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: emptyPayload)
        XCTAssertThrowsError(try emptyPayloadSigner.encodeSignedPayload()) { error in
            guard case StellarSDKError.invalidArgument = error else {
                return XCTFail("Unexpected error type: \(error)")
            }
        }
        XCTAssertThrowsError(try Signer.signedPayload(accountId: accountId, payload: emptyPayload)) { error in
            guard case StellarSDKError.invalidArgument = error else {
                return XCTFail("Unexpected error type: \(error)")
            }
        }

        // A body whose length field, width or padding breaks the framing is refused on the
        // encoding path, so no strkey the decoder would reject is emitted for it
        let signerKey = Data(pk.wrappedData32().wrapped)
        let malformedBodies: [(body: Data, reason: String)] = [
            (Data(), "no body at all"),
            (signerKey, "no length field"),
            (signerKey + Data([0x00, 0x00, 0x00, 0x00]), "length field zero"),
            (signerKey + Data([0x00, 0x00, 0x00, 0x41]) + Data(repeating: 0x01, count: 65) + Data(repeating: 0x00, count: 3),
             "length field over the maximum"),
            (signerKey + Data([0x00, 0x00, 0x00, 0x04]) + Data(repeating: 0x01, count: 8),
             "body wider than its length field allows"),
            (signerKey + Data([0x00, 0x00, 0x00, 0x05]) + Data(repeating: 0x01, count: 5),
             "body not padded to a multiple of four bytes"),
            (signerKey + Data([0x00, 0x00, 0x00, 0x05]) + Data(repeating: 0x01, count: 5) + Data([0x00, 0x00, 0x01]),
             "padding byte not zero")
        ]
        for (body, reason) in malformedBodies {
            do {
                _ = try body.encodeSignedPayload()
                XCTFail("Expected error for \(reason)")
            } catch StellarSDKError.invalidArgument {
                // Expected
            } catch {
                XCTFail("Unexpected error type for \(reason): \(error)")
            }
        }
    }

    // MARK: - Hex Conversion Function Tests

    func testHexConversionFunctions() throws {
        // Test encodeContractIdHex with valid hex
        let contractHex = "363eaa3867841fbad0f4ed88c779e4fe66e56a2470dc98c0ec9c073d05c7b103"
        let contractStrKey = try contractHex.encodeContractIdHex()
        XCTAssertEqual(contractStrKey, "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE")
        XCTAssertTrue(contractStrKey.isValidContractId())

        // Test encodeContractIdHex with a string that is not hexadecimal, and with the empty
        // string, which is valid hexadecimal but holds none of the bytes a contract id is
        for invalidHex in ["ZZZZ", "123", ""] {
            XCTAssertThrowsError(try invalidHex.encodeContractIdHex()) { error in
                guard case StellarSDKError.invalidArgument = error else {
                    return XCTFail("Unexpected error type for \"\(invalidHex)\": \(error)")
                }
            }
        }

        // Test encodeLiquidityPoolIdHex with valid hex
        let liquidityPoolHex = "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"
        let liquidityPoolStrKey = try liquidityPoolHex.encodeLiquidityPoolIdHex()
        XCTAssertEqual(liquidityPoolStrKey, "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN")
        XCTAssertTrue(liquidityPoolStrKey.isValidLiquidityPoolId())

        // Test encodeLiquidityPoolIdHex with invalid hex
        for invalidHex in ["not-hex", "ghijkl"] {
            XCTAssertThrowsError(try invalidHex.encodeLiquidityPoolIdHex()) { error in
                guard case StellarSDKError.invalidArgument = error else {
                    return XCTFail("Unexpected error type for \"\(invalidHex)\": \(error)")
                }
            }
        }

        // Test encodeClaimableBalanceIdHex with valid hex (with type discriminant missing)
        let claimableBalanceHex = "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"
        let claimableBalanceStrKey = try claimableBalanceHex.encodeClaimableBalanceIdHex()
        XCTAssertEqual(claimableBalanceStrKey, "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU")
        XCTAssertTrue(claimableBalanceStrKey.isValidClaimableBalanceId())

        // The 72 character hex Horizon reports, the four byte XDR union discriminant in front
        // of the same id, names that same claimable balance id
        let horizonHex = "00000000" + claimableBalanceHex
        XCTAssertEqual(horizonHex.count, 72)
        XCTAssertEqual(try horizonHex.encodeClaimableBalanceIdHex(), claimableBalanceStrKey)

        // Test encodeClaimableBalanceIdHex with invalid hex
        XCTAssertThrowsError(try "xyz123".encodeClaimableBalanceIdHex()) { error in
            guard case StellarSDKError.invalidArgument = error else {
                return XCTFail("Unexpected error type: \(error)")
            }
        }
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

        // A checksum that does not match the body it follows. The final symbol of a 58
        // character strkey carries the low three bits of the checksum and two bits the
        // encoding leaves unused, and a final "A" keeps those unused bits zero, so the
        // string is canonical base32 and only the checksum is wrong.
        let brokenChecksum = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TA"
        XCTAssertFalse(brokenChecksum.isValidClaimableBalanceId())
        XCTAssertThrowsError(try brokenChecksum.decodeClaimableBalanceId()) { error in
            guard case KeyUtilsError.invalidChecksum = error else {
                return XCTFail("Unexpected error type: \(error)")
            }
        }

        // A final "X" sets those unused bits instead, which the canonical re-encode rejects
        // before the checksum is compared.
        let nonCanonical = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TX"
        XCTAssertFalse(nonCanonical.isValidClaimableBalanceId())
        XCTAssertThrowsError(try nonCanonical.decodeClaimableBalanceId()) { error in
            guard case KeyUtilsError.invalidEncodedString = error else {
                return XCTFail("Unexpected error type: \(error)")
            }
        }

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

        // Test invalidEncodedString error for a signed payload whose body does not carry the
        // framing SEP-23 defines: a length field naming a width the body does not have, a
        // body padded with a byte that is not zero, a zero length field and a length field
        // one over the maximum
        for (signedPayload, reason) in sep23InvalidSignedPayloads + malformedFramingSignedPayloads {
            do {
                _ = try signedPayload.decodeSignedPayload()
                XCTFail("Expected error for \(reason)")
            } catch KeyUtilsError.invalidEncodedString {
                // Expected
            } catch {
                XCTFail("Unexpected error type for \(reason): \(error)")
            }
        }

        // Test invalidEncodedString error for a strkey encoded in a length the signed payload
        // version byte does not allow. The encoded length is checked before the version byte,
        // so the 56 characters of an account id handed to the signed payload decoder are
        // reported as a length that version byte does not allow, not as a wrong version byte.
        do {
            _ = try accountIdEncoded.decodeSignedPayload()
            XCTFail("Expected error")
        } catch KeyUtilsError.invalidEncodedString {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        // Test invalidEncodedString error on both decoding paths for a claimable balance id
        // whose body opens with a type the XDR union does not define
        do {
            _ = try sep23InvalidClaimableBalanceType.decodeClaimableBalanceId()
            XCTFail("Expected error")
        } catch KeyUtilsError.invalidEncodedString {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        do {
            _ = try sep23InvalidClaimableBalanceType.decodeClaimableBalanceIdToHex()
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

        // Test that a corrupted checksum is rejected on every path that decodes an
        // account id, instead of yielding the key of the uncorrupted address
        do {
            _ = try corruptedChecksumAccountId.decodeEd25519PublicKey()
            XCTFail("Expected error")
        } catch KeyUtilsError.invalidChecksum {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        do {
            _ = try PublicKey(accountId: corruptedChecksumAccountId)
            XCTFail("Expected error")
        } catch Ed25519Error.invalidPublicKey {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        do {
            _ = try KeyPair(accountId: corruptedChecksumAccountId)
            XCTFail("Expected error")
        } catch Ed25519Error.invalidPublicKey {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        do {
            _ = try corruptedChecksumAccountId.decodeMuxedAccount()
            XCTFail("Expected error")
        } catch Ed25519Error.invalidPublicKey {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        // A muxed address takes the other branch of decodeMuxedAccount, which reports a
        // malformed address as a KeyUtilsError rather than an Ed25519Error
        do {
            _ = try corruptedChecksumMuxedAccountId.decodeMuxedAccount()
            XCTFail("Expected error")
        } catch KeyUtilsError.invalidChecksum {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        do {
            _ = try SCAddressXDR(accountId: corruptedChecksumAccountId)
            XCTFail("Expected error")
        } catch Ed25519Error.invalidPublicKey {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        // Test invalidPublicKey error for strkeys that carry a matching checksum but a
        // version byte other than the ed25519 public key one
        let publicKeyData = Data(keyPair.publicKey.bytes)
        for strKey in [seedEncoded, muxedAccountId, try publicKeyData.encodePreAuthTx(), try publicKeyData.encodeSha256Hash()] {
            do {
                _ = try PublicKey(accountId: strKey)
                XCTFail("Expected error for \"\(strKey)\"")
            } catch Ed25519Error.invalidPublicKey {
                // Expected
            } catch {
                XCTFail("Unexpected error type for \"\(strKey)\": \(error)")
            }
        }

        // Test invalidPublicKey error for account ids that are too short to be decoded
        for accountId in ["GA", "GAAA", "GAAAA"] {
            do {
                _ = try PublicKey(accountId: accountId)
                XCTFail("Expected error for \"\(accountId)\"")
            } catch Ed25519Error.invalidPublicKey {
                // Expected
            } catch {
                XCTFail("Unexpected error type for \"\(accountId)\": \(error)")
            }

            do {
                _ = try KeyPair(accountId: accountId)
                XCTFail("Expected error for \"\(accountId)\"")
            } catch Ed25519Error.invalidPublicKey {
                // Expected
            } catch {
                XCTFail("Unexpected error type for \"\(accountId)\": \(error)")
            }
        }

        // Test that a corrupted checksum is rejected on every path that imports a secret
        // seed, instead of yielding the seed of the uncorrupted secret
        do {
            _ = try corruptedChecksumSecretSeed.decodeEd25519SecretSeed()
            XCTFail("Expected error")
        } catch KeyUtilsError.invalidChecksum {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        do {
            _ = try Seed(secret: corruptedChecksumSecretSeed)
            XCTFail("Expected error")
        } catch Ed25519Error.invalidSeed {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        do {
            _ = try KeyPair(secretSeed: corruptedChecksumSecretSeed)
            XCTFail("Expected error")
        } catch Ed25519Error.invalidSeed {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        // Test invalidSeed error for strkeys that carry a matching checksum but a version
        // byte other than the ed25519 secret seed one
        for strKey in [accountIdEncoded, muxedAccountId, try publicKeyData.encodePreAuthTx(), try publicKeyData.encodeSha256Hash()] {
            do {
                _ = try Seed(secret: strKey)
                XCTFail("Expected error for \"\(strKey)\"")
            } catch Ed25519Error.invalidSeed {
                // Expected
            } catch {
                XCTFail("Unexpected error type for \"\(strKey)\": \(error)")
            }

            do {
                _ = try KeyPair(secretSeed: strKey)
                XCTFail("Expected error for \"\(strKey)\"")
            } catch Ed25519Error.invalidSeed {
                // Expected
            } catch {
                XCTFail("Unexpected error type for \"\(strKey)\": \(error)")
            }
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
            
            // The address reports the id in the 72 character form Horizon serves, while the
            // strkey decodes to the 66 character body: the same hash, behind a discriminant
            // one byte wide instead of four.
            let hext = try strKey.decodeClaimableBalanceIdToHex()
            XCTAssertTrue(hext.hasPrefix("00"))
            XCTAssertEqual(bid, "00000000" + hext.dropFirst(2))
        default:
            XCTFail("not invoke contract host function")
            
        }
    }
}
