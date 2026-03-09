//
//  Sep23DocTest.swift
//  stellarsdkIntegrationTests
//
//  Tests for SEP-23 documentation code examples.
//  SEP-23: Strkey Encoding.
//

import Foundation
import Security
import XCTest
import stellarsdk

class Sep23DocTest: XCTestCase {

    // MARK: - Quick example

    func testQuickExample() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let accountId = keyPair.accountId

        // Validate an address
        XCTAssertTrue(accountId.isValidEd25519PublicKey())

        // Decode to raw bytes and encode back
        let rawPublicKey: Data = try accountId.decodeEd25519PublicKey()
        let encoded: String = try rawPublicKey.encodeEd25519PublicKey()
        XCTAssertEqual(encoded, accountId)
    }

    // MARK: - Account IDs and secret seeds

    func testAccountIdsAndSecretSeeds() throws {
        let keyPair = try KeyPair(secretSeed: "SAKEEHNTJXQTHU64TYNKP3ET56RSCB4ZHXYZRPEULNHUBDN4L2TWAECA")
        let accountId = keyPair.accountId
        let secretSeed = keyPair.secretSeed!

        // Validate
        XCTAssertTrue(accountId.isValidEd25519PublicKey())
        XCTAssertTrue(secretSeed.isValidEd25519SecretSeed())

        // Decode to raw 32-byte keys
        let rawPublicKey: Data = try accountId.decodeEd25519PublicKey()
        XCTAssertEqual(rawPublicKey.count, 32)

        let rawPrivateKey: Data = try secretSeed.decodeEd25519SecretSeed()
        XCTAssertEqual(rawPrivateKey.count, 32)

        // Encode raw bytes back to string
        let encodedAccountId: String = try rawPublicKey.encodeEd25519PublicKey()
        let encodedSeed: String = try rawPrivateKey.encodeEd25519SecretSeed()
        XCTAssertEqual(encodedAccountId, accountId)
        XCTAssertEqual(encodedSeed, secretSeed)

        // Derive account ID from seed
        let derivedAccountId = try KeyPair(secretSeed: secretSeed).accountId
        XCTAssertEqual(derivedAccountId, accountId)
    }

    // MARK: - Creating muxed accounts

    func testCreatingMuxedAccounts() throws {
        let accountId = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
        let userId: UInt64 = 1234567890

        let muxedAccount = try MuxedAccount(accountId: accountId, id: userId)
        let muxedAccountId = muxedAccount.accountId
        XCTAssertTrue(muxedAccountId.hasPrefix("M"))

        // Parse an existing M-address
        let parsedMuxed = try MuxedAccount(
            accountId: "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"
        )
        XCTAssertTrue(parsedMuxed.accountId.hasPrefix("M"))
    }

    // MARK: - Extracting muxed account components

    func testExtractingMuxedAccountComponents() throws {
        let muxedAccountId =
            "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"

        let muxedAccount = try MuxedAccount(accountId: muxedAccountId)

        let ed25519AccountId = muxedAccount.ed25519AccountId
        XCTAssertTrue(ed25519AccountId.hasPrefix("G"))
        XCTAssertEqual(ed25519AccountId, "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")

        let id: UInt64? = muxedAccount.id
        XCTAssertNotNil(id)

        let accountIdResult = muxedAccount.accountId
        XCTAssertTrue(accountIdResult.hasPrefix("M"))
    }

    // MARK: - Low-level muxed account encoding

    func testLowLevelMuxedAccountEncoding() throws {
        let muxedAccountId =
            "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"

        // Validate M-address format
        XCTAssertTrue(muxedAccountId.isValidMed25519PublicKey())

        // Decode to MuxedAccountXDR
        let muxedXdr: MuxedAccountXDR = try muxedAccountId.decodeMuxedAccount()
        XCTAssertNotNil(muxedXdr.id)

        // Decode to raw binary
        let rawData: Data = try muxedAccountId.decodeMed25519PublicKey()
        XCTAssertFalse(rawData.isEmpty)

        // Encode raw binary back to M-address
        let encoded: String = try rawData.encodeMEd25519AccountId()
        XCTAssertTrue(encoded.isValidMed25519PublicKey())
    }

    // MARK: - Pre-auth TX and SHA-256 hashes

    func testPreAuthTxAndSha256Hashes() throws {
        // Pre-auth TX (T...)
        var transactionHash = Data(count: 32)
        _ = transactionHash.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        let preAuthTx: String = try transactionHash.encodePreAuthTx()
        XCTAssertTrue(preAuthTx.isValidPreAuthTx())
        let decodedPreAuth: Data = try preAuthTx.decodePreAuthTx()
        XCTAssertEqual(decodedPreAuth, transactionHash)

        // SHA-256 hash signer (X...)
        var hash = Data(count: 32)
        _ = hash.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        let hashSigner: String = try hash.encodeSha256Hash()
        XCTAssertTrue(hashSigner.isValidSha256Hash())
        let decodedHash: Data = try hashSigner.decodeSha256Hash()
        XCTAssertEqual(decodedHash, hash)
    }

    // MARK: - Contract IDs (C...)

    func testContractIds() throws {
        // Use 32 random bytes as a contract hash
        let keyPair = try KeyPair.generateRandomKeyPair()
        let contractHash = Data(keyPair.publicKey.bytes)
        let contractId: String = try contractHash.encodeContractId()

        // Validate
        XCTAssertTrue(contractId.isValidContractId())
        XCTAssertTrue(contractId.hasPrefix("C"))

        // Decode to raw bytes or hex
        let raw: Data = try contractId.decodeContractId()
        XCTAssertEqual(raw.count, 32)
        let hex: String = try contractId.decodeContractIdToHex()
        XCTAssertEqual(hex.count, 64)

        // Encode from raw bytes or hex
        let encodedFromBytes: String = try raw.encodeContractId()
        let encodedFromHex: String = try hex.encodeContractIdHex()
        XCTAssertEqual(encodedFromBytes, contractId)
        XCTAssertEqual(encodedFromHex, contractId)
    }

    // MARK: - Signed payloads (P...)

    func testSignedPayloads() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let payload = Data([0x01, 0x02, 0x03, 0x04])

        let pk = try PublicKey(accountId: keyPair.accountId)
        let signedPayload = Ed25519SignedPayload(ed25519: pk.wrappedData32(), payload: payload)
        let signedPayloadStr: String = try signedPayload.encodeSignedPayload()
        XCTAssertTrue(signedPayloadStr.isValidSignedPayload())

        let decoded: Ed25519SignedPayload = try signedPayloadStr.decodeSignedPayload()
        let signerPublicKey: PublicKey = try decoded.publicKey()
        XCTAssertEqual(signerPublicKey.accountId, keyPair.accountId)
        XCTAssertEqual(decoded.payload, payload)
    }

    // MARK: - Liquidity pool and claimable balance IDs

    func testLiquidityPoolIds() throws {
        let poolHex =
            "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let poolId: String = try poolHex.encodeLiquidityPoolIdHex()
        XCTAssertTrue(poolId.isValidLiquidityPoolId())

        let decodedPool: Data = try poolId.decodeLiquidityPoolId()
        XCTAssertEqual(decodedPool.count, 32)

        // Round-trip via hex
        let decodedHex: String = try poolId.decodeLiquidityPoolIdToHex()
        XCTAssertEqual(decodedHex, poolHex)
    }

    func testClaimableBalanceIds() throws {
        // Use a known 32-byte hex value
        let balanceHex =
            "929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfd00000000"
        let balanceId: String = try balanceHex.encodeClaimableBalanceIdHex()
        XCTAssertTrue(balanceId.isValidClaimableBalanceId())

        let decodedBalance: Data = try balanceId.decodeClaimableBalanceId()
        // 33 bytes: 1-byte discriminant + 32-byte ID
        XCTAssertEqual(decodedBalance.count, 33)
    }

    // MARK: - Validation

    func testValidation() throws {
        // G-address validation
        XCTAssertTrue("GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ".isValidEd25519PublicKey())
        XCTAssertFalse("INVALID".isValidEd25519PublicKey())

        // S-address validation
        XCTAssertTrue("SAKEEHNTJXQTHU64TYNKP3ET56RSCB4ZHXYZRPEULNHUBDN4L2TWAECA".isValidEd25519SecretSeed())
        XCTAssertFalse("GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ".isValidEd25519SecretSeed())

        // M-address validation
        XCTAssertTrue("MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK".isValidMed25519PublicKey())

        // Cross-type validation: S-address is not a valid G-address
        XCTAssertFalse("SAKEEHNTJXQTHU64TYNKP3ET56RSCB4ZHXYZRPEULNHUBDN4L2TWAECA".isValidEd25519PublicKey())
    }

    // MARK: - Error handling

    func testErrorHandlingInvalidDecode() {
        // Invalid address throws
        XCTAssertThrowsError(try "GINVALIDADDRESS".decodeEd25519PublicKey())
    }

    func testErrorHandlingInvalidMuxedAccount() {
        // MuxedAccount validates on construction
        XCTAssertThrowsError(try MuxedAccount(accountId: "INVALID", id: 123))
    }

    func testErrorHandlingAddressTypeCheck() throws {
        // Use validation to avoid exceptions
        let gAddress = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"

        if gAddress.isValidEd25519PublicKey() {
            let raw: Data = try gAddress.decodeEd25519PublicKey()
            XCTAssertEqual(raw.count, 32)
        } else if gAddress.isValidMed25519PublicKey() {
            XCTFail("Should not be detected as M-address")
        } else {
            XCTFail("Should be detected as valid G-address")
        }
    }
}
