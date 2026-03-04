//
//  XDRTypesUnitTests.swift
//  stellarsdkTests
//
//  Tests for types defined in Stellar-types.x
//

import XCTest
import stellarsdk

class XDRTypesUnitTests: XCTestCase {

    // MARK: - CryptoKeyType (enum with Equatable)

    func testCryptoKeyTypeEd25519RoundTrip() throws {
        let original = CryptoKeyType.ed25519
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(CryptoKeyType.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testCryptoKeyTypePreAuthTxRoundTrip() throws {
        let original = CryptoKeyType.preAuthTx
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(CryptoKeyType.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testCryptoKeyTypeHashXRoundTrip() throws {
        let original = CryptoKeyType.hashX
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(CryptoKeyType.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testCryptoKeyTypeEd25519SignedPayloadRoundTrip() throws {
        let original = CryptoKeyType.ed25519SignedPayload
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(CryptoKeyType.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testCryptoKeyTypeMuxedEd25519RoundTrip() throws {
        let original = CryptoKeyType.muxedEd25519
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(CryptoKeyType.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testCryptoKeyTypeRawValues() {
        XCTAssertEqual(CryptoKeyType.ed25519.rawValue, 0)
        XCTAssertEqual(CryptoKeyType.preAuthTx.rawValue, 1)
        XCTAssertEqual(CryptoKeyType.hashX.rawValue, 2)
        XCTAssertEqual(CryptoKeyType.ed25519SignedPayload.rawValue, 3)
        XCTAssertEqual(CryptoKeyType.muxedEd25519.rawValue, 256)
    }

    func testCryptoKeyTypeAllCasesRoundTrip() throws {
        let allCases: [CryptoKeyType] = [.ed25519, .preAuthTx, .hashX, .ed25519SignedPayload, .muxedEd25519]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(CryptoKeyType.self, data: encoded)
            XCTAssertEqual(original, decoded, "Round-trip failed for \(original)")
        }
    }

    // MARK: - PublicKeyTypeXDR (enum with Equatable)

    func testPublicKeyTypeXDRRoundTrip() throws {
        let original = PublicKeyTypeXDR.publicKeyTypeEd25519
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(PublicKeyTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testPublicKeyTypeXDRRawValue() {
        XCTAssertEqual(PublicKeyTypeXDR.publicKeyTypeEd25519.rawValue, 0)
    }

    // MARK: - SignerKeyType (enum with Equatable)

    func testSignerKeyTypeEd25519RoundTrip() throws {
        let original = SignerKeyType.ed25519
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SignerKeyType.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testSignerKeyTypePreAuthTxRoundTrip() throws {
        let original = SignerKeyType.preAuthTx
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SignerKeyType.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testSignerKeyTypeHashXRoundTrip() throws {
        let original = SignerKeyType.hashX
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SignerKeyType.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testSignerKeyTypeSignedPayloadRoundTrip() throws {
        let original = SignerKeyType.signedPayload
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SignerKeyType.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testSignerKeyTypeRawValues() {
        XCTAssertEqual(SignerKeyType.ed25519.rawValue, 0)
        XCTAssertEqual(SignerKeyType.preAuthTx.rawValue, 1)
        XCTAssertEqual(SignerKeyType.hashX.rawValue, 2)
        XCTAssertEqual(SignerKeyType.signedPayload.rawValue, 3)
    }

    func testSignerKeyTypeAllCasesRoundTrip() throws {
        let allCases: [SignerKeyType] = [.ed25519, .preAuthTx, .hashX, .signedPayload]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(SignerKeyType.self, data: encoded)
            XCTAssertEqual(original, decoded, "Round-trip failed for \(original)")
        }
    }

    // MARK: - BinaryFuseFilterTypeXDR (enum with Equatable)

    func testBinaryFuseFilterTypeEightBitRoundTrip() throws {
        let original = BinaryFuseFilterTypeXDR.eightBit
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BinaryFuseFilterTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testBinaryFuseFilterTypeSixteenBitRoundTrip() throws {
        let original = BinaryFuseFilterTypeXDR.sixteenBit
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BinaryFuseFilterTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testBinaryFuseFilterTypeThirtyTwoBitRoundTrip() throws {
        let original = BinaryFuseFilterTypeXDR.thirtyTwoBit
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(BinaryFuseFilterTypeXDR.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testBinaryFuseFilterTypeRawValues() {
        XCTAssertEqual(BinaryFuseFilterTypeXDR.eightBit.rawValue, 0)
        XCTAssertEqual(BinaryFuseFilterTypeXDR.sixteenBit.rawValue, 1)
        XCTAssertEqual(BinaryFuseFilterTypeXDR.thirtyTwoBit.rawValue, 2)
    }

    func testBinaryFuseFilterTypeAllCasesRoundTrip() throws {
        let allCases: [BinaryFuseFilterTypeXDR] = [.eightBit, .sixteenBit, .thirtyTwoBit]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(BinaryFuseFilterTypeXDR.self, data: encoded)
            XCTAssertEqual(original, decoded, "Round-trip failed for \(original)")
        }
    }

    // MARK: - ClaimableBalanceIDType (enum with Equatable)

    func testClaimableBalanceIDTypeRoundTrip() throws {
        let original = ClaimableBalanceIDType.claimableBalanceIDTypeV0
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimableBalanceIDType.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testClaimableBalanceIDTypeRawValue() {
        XCTAssertEqual(ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue, 0)
    }

    // MARK: - Curve25519SecretXDR (struct, no Equatable)

    func testCurve25519SecretXDRRoundTrip() throws {
        let keyData = WrappedData32(Data(repeating: 0xAB, count: 32))
        let original = Curve25519SecretXDR(key: keyData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(Curve25519SecretXDR.self, data: encoded)
        XCTAssertEqual(decoded.key.wrapped, keyData.wrapped)
    }

    func testCurve25519SecretXDRWithRealisticKey() throws {
        var keyBytes = Data(count: 32)
        for i in 0..<32 { keyBytes[i] = UInt8(i) }
        let keyData = WrappedData32(keyBytes)
        let original = Curve25519SecretXDR(key: keyData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(Curve25519SecretXDR.self, data: encoded)
        XCTAssertEqual(decoded.key.wrapped, keyBytes)
    }

    func testCurve25519SecretXDRDeterministicEncoding() throws {
        let keyData = WrappedData32(Data(repeating: 0x55, count: 32))
        let original = Curve25519SecretXDR(key: keyData)
        let encoded1 = try XDREncoder.encode(original)
        let encoded2 = try XDREncoder.encode(original)
        XCTAssertEqual(encoded1, encoded2)
    }

    // MARK: - Curve25519PublicXDR (struct, no Equatable)

    func testCurve25519PublicXDRRoundTrip() throws {
        let keyData = WrappedData32(Data(repeating: 0xCD, count: 32))
        let original = Curve25519PublicXDR(key: keyData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(Curve25519PublicXDR.self, data: encoded)
        XCTAssertEqual(decoded.key.wrapped, keyData.wrapped)
    }

    func testCurve25519PublicXDRWithRealisticKey() throws {
        var keyBytes = Data(count: 32)
        for i in 0..<32 { keyBytes[i] = UInt8(255 - i) }
        let keyData = WrappedData32(keyBytes)
        let original = Curve25519PublicXDR(key: keyData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(Curve25519PublicXDR.self, data: encoded)
        XCTAssertEqual(decoded.key.wrapped, keyBytes)
    }

    func testCurve25519PublicXDRDeterministicEncoding() throws {
        let keyData = WrappedData32(Data(repeating: 0x99, count: 32))
        let original = Curve25519PublicXDR(key: keyData)
        let encoded1 = try XDREncoder.encode(original)
        let encoded2 = try XDREncoder.encode(original)
        XCTAssertEqual(encoded1, encoded2)
    }

    // MARK: - HmacSha256KeyXDR (struct, no Equatable)

    func testHmacSha256KeyXDRRoundTrip() throws {
        let keyData = WrappedData32(Data(repeating: 0xDE, count: 32))
        let original = HmacSha256KeyXDR(key: keyData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HmacSha256KeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.key.wrapped, keyData.wrapped)
    }

    func testHmacSha256KeyXDRWithSequentialBytes() throws {
        var keyBytes = Data(count: 32)
        for i in 0..<32 { keyBytes[i] = UInt8(i * 7 % 256) }
        let keyData = WrappedData32(keyBytes)
        let original = HmacSha256KeyXDR(key: keyData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HmacSha256KeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.key.wrapped, keyBytes)
    }

    // MARK: - HmacSha256MacXDR (struct, no Equatable)

    func testHmacSha256MacXDRRoundTrip() throws {
        let macData = WrappedData32(Data(repeating: 0xBE, count: 32))
        let original = HmacSha256MacXDR(mac: macData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HmacSha256MacXDR.self, data: encoded)
        XCTAssertEqual(decoded.mac.wrapped, macData.wrapped)
    }

    func testHmacSha256MacXDRWithRealisticMac() throws {
        // Simulate a realistic HMAC output with varied bytes
        var macBytes = Data(count: 32)
        for i in 0..<32 { macBytes[i] = UInt8((i * 13 + 7) % 256) }
        let macData = WrappedData32(macBytes)
        let original = HmacSha256MacXDR(mac: macData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(HmacSha256MacXDR.self, data: encoded)
        XCTAssertEqual(decoded.mac.wrapped, macBytes)
    }

    // MARK: - ShortHashSeedXDR (struct, no Equatable)

    func testShortHashSeedXDRRoundTrip() throws {
        let seedData = WrappedData16(Data(repeating: 0x42, count: 16))
        let original = ShortHashSeedXDR(seed: seedData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ShortHashSeedXDR.self, data: encoded)
        XCTAssertEqual(decoded.seed.wrapped, seedData.wrapped)
    }

    func testShortHashSeedXDRWithRealisticSeed() throws {
        var seedBytes = Data(count: 16)
        for i in 0..<16 { seedBytes[i] = UInt8(i * 17 % 256) }
        let seedData = WrappedData16(seedBytes)
        let original = ShortHashSeedXDR(seed: seedData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ShortHashSeedXDR.self, data: encoded)
        XCTAssertEqual(decoded.seed.wrapped, seedBytes)
    }

    // MARK: - Ed25519SignedPayload (struct, no Equatable)

    func testEd25519SignedPayloadRoundTrip() throws {
        let keyData = WrappedData32(Data(repeating: 0xAA, count: 32))
        let payload = Data(repeating: 0xBB, count: 32)
        let original = Ed25519SignedPayload(ed25519: keyData, payload: payload)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(Ed25519SignedPayload.self, data: encoded)
        XCTAssertEqual(decoded.ed25519.wrapped, keyData.wrapped)
        XCTAssertEqual(decoded.payload, payload)
    }

    func testEd25519SignedPayloadWithMaxPayload() throws {
        let keyData = WrappedData32(Data(repeating: 0x11, count: 32))
        let payload = Data(repeating: 0xFF, count: 64) // max payload is 64 bytes
        let original = Ed25519SignedPayload(ed25519: keyData, payload: payload)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(Ed25519SignedPayload.self, data: encoded)
        XCTAssertEqual(decoded.ed25519.wrapped, keyData.wrapped)
        XCTAssertEqual(decoded.payload, payload)
        XCTAssertEqual(decoded.payload.count, 64)
    }

    func testEd25519SignedPayloadWithMinPayload() throws {
        let keyData = WrappedData32(Data(repeating: 0x22, count: 32))
        let payload = Data([0x01]) // minimal payload
        let original = Ed25519SignedPayload(ed25519: keyData, payload: payload)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(Ed25519SignedPayload.self, data: encoded)
        XCTAssertEqual(decoded.ed25519.wrapped, keyData.wrapped)
        XCTAssertEqual(decoded.payload, payload)
        XCTAssertEqual(decoded.payload.count, 1)
    }

    // MARK: - SerializedBinaryFuseFilterXDR (struct, no Equatable)

    func testSerializedBinaryFuseFilterXDRRoundTrip() throws {
        let inputSeed = ShortHashSeedXDR(seed: WrappedData16(Data(repeating: 0x11, count: 16)))
        let filterSeed = ShortHashSeedXDR(seed: WrappedData16(Data(repeating: 0x22, count: 16)))
        let fingerprints = Data([0x01, 0x02, 0x03, 0x04, 0x05])

        let original = SerializedBinaryFuseFilterXDR(
            type: .eightBit,
            inputHashSeed: inputSeed,
            filterSeed: filterSeed,
            segmentLength: 1024,
            segementLengthMask: 1023,
            segmentCount: 3,
            segmentCountLength: 3072,
            fingerprintLength: 5,
            fingerprints: fingerprints
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SerializedBinaryFuseFilterXDR.self, data: encoded)

        XCTAssertEqual(decoded.type, .eightBit)
        XCTAssertEqual(decoded.inputHashSeed.seed.wrapped, inputSeed.seed.wrapped)
        XCTAssertEqual(decoded.filterSeed.seed.wrapped, filterSeed.seed.wrapped)
        XCTAssertEqual(decoded.segmentLength, 1024)
        XCTAssertEqual(decoded.segementLengthMask, 1023)
        XCTAssertEqual(decoded.segmentCount, 3)
        XCTAssertEqual(decoded.segmentCountLength, 3072)
        XCTAssertEqual(decoded.fingerprintLength, 5)
        XCTAssertEqual(decoded.fingerprints, fingerprints)
    }

    func testSerializedBinaryFuseFilterXDRWithSixteenBitType() throws {
        let inputSeed = ShortHashSeedXDR(seed: WrappedData16(Data(repeating: 0xAA, count: 16)))
        let filterSeed = ShortHashSeedXDR(seed: WrappedData16(Data(repeating: 0xBB, count: 16)))
        let fingerprints = Data(repeating: 0xCC, count: 20)

        let original = SerializedBinaryFuseFilterXDR(
            type: .sixteenBit,
            inputHashSeed: inputSeed,
            filterSeed: filterSeed,
            segmentLength: 2048,
            segementLengthMask: 2047,
            segmentCount: 5,
            segmentCountLength: 10240,
            fingerprintLength: 10,
            fingerprints: fingerprints
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SerializedBinaryFuseFilterXDR.self, data: encoded)

        XCTAssertEqual(decoded.type, .sixteenBit)
        XCTAssertEqual(decoded.inputHashSeed.seed.wrapped, inputSeed.seed.wrapped)
        XCTAssertEqual(decoded.filterSeed.seed.wrapped, filterSeed.seed.wrapped)
        XCTAssertEqual(decoded.segmentLength, 2048)
        XCTAssertEqual(decoded.segementLengthMask, 2047)
        XCTAssertEqual(decoded.segmentCount, 5)
        XCTAssertEqual(decoded.segmentCountLength, 10240)
        XCTAssertEqual(decoded.fingerprintLength, 10)
        XCTAssertEqual(decoded.fingerprints, fingerprints)
    }

    func testSerializedBinaryFuseFilterXDRWithThirtyTwoBitType() throws {
        let inputSeed = ShortHashSeedXDR(seed: WrappedData16(Data(repeating: 0xDD, count: 16)))
        let filterSeed = ShortHashSeedXDR(seed: WrappedData16(Data(repeating: 0xEE, count: 16)))
        let fingerprints = Data(repeating: 0xFF, count: 40)

        let original = SerializedBinaryFuseFilterXDR(
            type: .thirtyTwoBit,
            inputHashSeed: inputSeed,
            filterSeed: filterSeed,
            segmentLength: 4096,
            segementLengthMask: 4095,
            segmentCount: 7,
            segmentCountLength: 28672,
            fingerprintLength: 10,
            fingerprints: fingerprints
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SerializedBinaryFuseFilterXDR.self, data: encoded)

        XCTAssertEqual(decoded.type, .thirtyTwoBit)
        XCTAssertEqual(decoded.inputHashSeed.seed.wrapped, inputSeed.seed.wrapped)
        XCTAssertEqual(decoded.filterSeed.seed.wrapped, filterSeed.seed.wrapped)
        XCTAssertEqual(decoded.segmentLength, 4096)
        XCTAssertEqual(decoded.segementLengthMask, 4095)
        XCTAssertEqual(decoded.segmentCount, 7)
        XCTAssertEqual(decoded.segmentCountLength, 28672)
        XCTAssertEqual(decoded.fingerprintLength, 10)
        XCTAssertEqual(decoded.fingerprints, fingerprints)
    }

    func testSerializedBinaryFuseFilterXDRWithEmptyFingerprints() throws {
        let inputSeed = ShortHashSeedXDR(seed: WrappedData16(Data(repeating: 0x33, count: 16)))
        let filterSeed = ShortHashSeedXDR(seed: WrappedData16(Data(repeating: 0x44, count: 16)))

        let original = SerializedBinaryFuseFilterXDR(
            type: .eightBit,
            inputHashSeed: inputSeed,
            filterSeed: filterSeed,
            segmentLength: 0,
            segementLengthMask: 0,
            segmentCount: 0,
            segmentCountLength: 0,
            fingerprintLength: 0,
            fingerprints: Data()
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SerializedBinaryFuseFilterXDR.self, data: encoded)

        XCTAssertEqual(decoded.type, .eightBit)
        XCTAssertEqual(decoded.segmentLength, 0)
        XCTAssertEqual(decoded.fingerprintLength, 0)
        XCTAssertEqual(decoded.fingerprints, Data())
    }

    func testSerializedBinaryFuseFilterXDRDeterministicEncoding() throws {
        let inputSeed = ShortHashSeedXDR(seed: WrappedData16(Data(repeating: 0x55, count: 16)))
        let filterSeed = ShortHashSeedXDR(seed: WrappedData16(Data(repeating: 0x66, count: 16)))

        let original = SerializedBinaryFuseFilterXDR(
            type: .sixteenBit,
            inputHashSeed: inputSeed,
            filterSeed: filterSeed,
            segmentLength: 512,
            segementLengthMask: 511,
            segmentCount: 2,
            segmentCountLength: 1024,
            fingerprintLength: 8,
            fingerprints: Data(repeating: 0x77, count: 16)
        )

        let encoded1 = try XDREncoder.encode(original)
        let encoded2 = try XDREncoder.encode(original)
        XCTAssertEqual(encoded1, encoded2)
    }

    // MARK: - ExtensionPoint (union, no Equatable) - supplemental test

    func testExtensionPointVoidRoundTrip() throws {
        let original = ExtensionPoint.void
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ExtensionPoint.self, data: encoded)
        XCTAssertEqual(decoded.type(), 0)
    }

    func testExtensionPointEncodedSize() throws {
        let original = ExtensionPoint.void
        let encoded = try XDREncoder.encode(original)
        // Extension point should encode as just a 4-byte Int32 discriminant (value 0)
        XCTAssertEqual(encoded.count, 4)
    }

    // MARK: - SignerKeyXDR (union) - supplemental tests

    func testSignerKeyXDREd25519RoundTrip() throws {
        let keyData = XDRTestHelpers.wrappedData32()
        let original = SignerKeyXDR.ed25519(keyData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SignerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), SignerKeyType.ed25519.rawValue)
        if case .ed25519(let decodedKey) = decoded {
            XCTAssertEqual(decodedKey.wrapped, keyData.wrapped)
        } else {
            XCTFail("Expected .ed25519 case")
        }
    }

    func testSignerKeyXDRPreAuthTxRoundTrip() throws {
        let hashData = WrappedData32(Data(repeating: 0xAA, count: 32))
        let original = SignerKeyXDR.preAuthTx(hashData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SignerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), SignerKeyType.preAuthTx.rawValue)
        if case .preAuthTx(let decodedHash) = decoded {
            XCTAssertEqual(decodedHash.wrapped, hashData.wrapped)
        } else {
            XCTFail("Expected .preAuthTx case")
        }
    }

    func testSignerKeyXDRHashXRoundTrip() throws {
        let hashData = WrappedData32(Data(repeating: 0xBB, count: 32))
        let original = SignerKeyXDR.hashX(hashData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SignerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), SignerKeyType.hashX.rawValue)
        if case .hashX(let decodedHash) = decoded {
            XCTAssertEqual(decodedHash.wrapped, hashData.wrapped)
        } else {
            XCTFail("Expected .hashX case")
        }
    }

    func testSignerKeyXDRSignedPayloadRoundTrip() throws {
        let keyData = WrappedData32(Data(repeating: 0xCC, count: 32))
        let payloadData = Data(repeating: 0xDD, count: 48)
        let signedPayload = Ed25519SignedPayload(ed25519: keyData, payload: payloadData)
        let original = SignerKeyXDR.signedPayload(signedPayload)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SignerKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), SignerKeyType.signedPayload.rawValue)
        if case .signedPayload(let decodedPayload) = decoded {
            XCTAssertEqual(decodedPayload.ed25519.wrapped, keyData.wrapped)
            XCTAssertEqual(decodedPayload.payload, payloadData)
        } else {
            XCTFail("Expected .signedPayload case")
        }
    }

    // MARK: - ClaimableBalanceIDXDR (union) - supplemental test

    func testClaimableBalanceIDXDRV0RoundTrip() throws {
        let hashData = XDRTestHelpers.wrappedData32()
        let original = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(hashData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ClaimableBalanceIDXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue)
        if case .claimableBalanceIDTypeV0(let decodedHash) = decoded {
            XCTAssertEqual(decodedHash.wrapped, hashData.wrapped)
        } else {
            XCTFail("Expected .claimableBalanceIDTypeV0 case")
        }
    }
}
