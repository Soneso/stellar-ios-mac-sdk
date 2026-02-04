//
//  SeedTestCase.swift
//  stellarsdkTests
//
//  Created on 03.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class SeedTestCase: XCTestCase {

    // Test vector from Java SDK - known valid secret seed and expected public key
    let knownSecret = "SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE"
    let expectedAccountId = "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D"

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // Test 1: Create seed from random and verify it's valid
    func testSeedFromRandom() throws {
        let seed = try Seed()

        // Verify seed is 32 bytes
        XCTAssertEqual(seed.bytes.count, StellarProtocolConstants.ED25519_SEED_SIZE)

        // Verify secret encoding starts with 'S'
        XCTAssertTrue(seed.secret.hasPrefix(StellarProtocolConstants.STRKEY_PREFIX_SEED))

        // Verify secret has correct length
        XCTAssertEqual(seed.secret.count, StellarProtocolConstants.STRKEY_ENCODED_LENGTH_STANDARD)

        // Verify we can create a keypair from the seed
        let keyPair = KeyPair(seed: seed)
        XCTAssertNotNil(keyPair.secretSeed)
        XCTAssertEqual(keyPair.secretSeed, seed.secret)
    }

    // Test 2: Create seed from known secret string
    func testSeedFromSecret() throws {
        let seed = try Seed(secret: knownSecret)

        // Verify seed is 32 bytes
        XCTAssertEqual(seed.bytes.count, StellarProtocolConstants.ED25519_SEED_SIZE)

        // Verify the secret round-trips correctly
        XCTAssertEqual(seed.secret, knownSecret)

        // Verify keypair created from this seed matches expected account ID
        let keyPair = KeyPair(seed: seed)
        XCTAssertEqual(keyPair.accountId, expectedAccountId)
        XCTAssertEqual(keyPair.secretSeed, knownSecret)
    }

    // Test 3: Create seed from raw bytes
    func testSeedFromBytes() throws {
        // Get bytes from a known secret
        let originalSeed = try Seed(secret: knownSecret)
        let bytes = originalSeed.bytes

        // Create new seed from those bytes
        let newSeed = try Seed(bytes: bytes)

        // Verify bytes match
        XCTAssertEqual(newSeed.bytes, bytes)

        // Verify secrets match
        XCTAssertEqual(newSeed.secret, knownSecret)

        // Verify keypair derivation works
        let keyPair1 = KeyPair(seed: originalSeed)
        let keyPair2 = KeyPair(seed: newSeed)
        XCTAssertEqual(keyPair1.accountId, keyPair2.accountId)
        XCTAssertEqual(keyPair1.secretSeed, keyPair2.secretSeed)
    }

    // Test 4: Invalid secret string throws error
    func testInvalidSecretThrows() {
        // Test various invalid secret seeds
        let invalidSecrets = [
            "",
            "hello",
            "SBWUBZ3SIPLLF5CCXLWUB2Z6UBTYAW34KVXOLRQ5HDAZG4ZY7MHNBWJ1", // Invalid checksum
            "masterpassphrasemasterpassphrase",
            "gsYRSEQhTffqA9opPepAENCr2WG6z5iBHHubxxbRzWaHf8FBWcu", // Not a Stellar secret
            "GBPXXOA5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL", // Valid public key, not seed
            "SAVZ4FJLGPUXPN4EPLWJBLZW3FZSHH2GQJA6KPB47BQZBZJ7XHVI3T6", // Too short
            "SAVZ4FJLGPUXPN4EPLWJBLZW3FZSHH2GQJA6KPB47BQZBZJ7XHVI3T6NA", // Too long
            "SCMB30FQCIQAWZ4WQTS6SVK37LGMAFJGXOZIHTH2PY6EXLP37G46H6DT", // Invalid checksum
        ]

        for invalidSecret in invalidSecrets {
            XCTAssertThrowsError(try Seed(secret: invalidSecret), "Should throw for invalid secret: \(invalidSecret)") { error in
                XCTAssertTrue(error is Ed25519Error)
            }
        }
    }

    // Test 5: Wrong byte length throws error
    func testInvalidBytesLengthThrows() {
        // Test various invalid byte lengths
        let invalidByteLengths = [0, 1, 16, 31, 33, 64]

        for length in invalidByteLengths {
            let bytes = [UInt8](repeating: 0, count: length)
            XCTAssertThrowsError(try Seed(bytes: bytes), "Should throw for \(length) bytes") { error in
                XCTAssertTrue(error is Ed25519Error)
                if let ed25519Error = error as? Ed25519Error {
                    if case Ed25519Error.invalidSeedLength = ed25519Error {
                        // Expected error type
                    } else {
                        XCTFail("Expected invalidSeedLength error, got \(ed25519Error)")
                    }
                }
            }
        }
    }

    // Test 6: Verify secret encoding roundtrip
    func testSeedSecretEncoding() throws {
        // Test multiple known test vectors from Java SDK
        let testVectors = [
            "SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE": "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D",
            "SDTQN6XUC3D2Z6TIG3XLUTJIMHOSON2FMSKCTM2OHKKH2UX56RQ7R5Y4": "GDEAOZWTVHQZGGJY6KG4NAGJQ6DXATXAJO3AMW7C4IXLKMPWWB4FDNFZ",
            "SDIREFASXYQVEI6RWCQW7F37E6YNXECQJ4SPIOFMMMJRU5CMDQVW32L5": "GD2EVR7DGDLNKWEG366FIKXO2KCUAIE3HBUQP4RNY7LEZR5LDKBYHMM6",
            "SDAPE6RHEJ7745VQEKCI2LMYKZB3H6H366I33A42DG7XKV57673XLCC2": "GDLXVH2BTLCLZM53GF7ELZFF4BW4MHH2WXEA4Z5Z3O6DPNZNR44A56UJ",
            "SDYZ5IYOML3LTWJ6WIAC2YWORKVO7GJRTPPGGNJQERH72I6ZCQHDAJZN": "GABXJTV7ELEB2TQZKJYEGXBUIG6QODJULKJDI65KZMIZZG2EACJU5EA7",
        ]

        for (secretSeed, expectedAccountId) in testVectors {
            // Create seed from secret
            let seed = try Seed(secret: secretSeed)

            // Verify the secret round-trips
            XCTAssertEqual(seed.secret, secretSeed, "Secret encoding round-trip failed for \(secretSeed)")

            // Extract bytes and create new seed
            let bytes = seed.bytes
            let recreatedSeed = try Seed(bytes: bytes)

            // Verify recreated seed has same secret
            XCTAssertEqual(recreatedSeed.secret, secretSeed, "Byte round-trip failed for \(secretSeed)")

            // Verify keypair derivation produces expected account ID
            let keyPair = KeyPair(seed: seed)
            XCTAssertEqual(keyPair.accountId, expectedAccountId, "Account ID mismatch for \(secretSeed)")
        }
    }

    // Additional test: Verify two random seeds are different
    func testRandomSeedsAreDifferent() throws {
        let seed1 = try Seed()
        let seed2 = try Seed()

        XCTAssertNotEqual(seed1.bytes, seed2.bytes)
        XCTAssertNotEqual(seed1.secret, seed2.secret)
    }

    // Additional test: Verify seed bytes are immutable (defensive copy)
    func testSeedBytesAreImmutable() throws {
        let seed = try Seed(secret: knownSecret)
        var bytes = seed.bytes

        // Modify the bytes array
        bytes[0] = bytes[0] &+ 1

        // Verify original seed bytes are unchanged
        XCTAssertNotEqual(bytes, seed.bytes, "Seed bytes should not be affected by external modifications")
    }
}
