//
//  TransactionStringBytesUnitTests.swift
//  stellarsdkUnitTests
//
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Envelopes whose memo, `SCVal` strings or function name hold bytes that are not valid UTF-8
/// or start with a byte order mark, and envelopes whose `SCVal` symbols start with a byte order
/// mark. The XDR layer and the transaction import keep those bytes, so the envelope, the hash
/// and every new signature are those of the input. The hashes are testnet hashes computed
/// outside the SDK.
final class TransactionStringBytesUnitTests: XCTestCase {

    private struct EnvelopeVector {
        let envelope: String
        let hash: String
    }

    /// A V0 envelope, its V1 form with the same fields and the hash under the V0 rule of core,
    /// `sha256(network id || ENVELOPE_TYPE_TX || 0 || tx)`, which equals the hash of the V1 form.
    private struct V0Vector {
        let envelope: String
        let v1Envelope: String
        let fee: UInt32
        let hash: String
    }

    private struct FeeBumpVector {
        let envelope: String
        let hash: String
        let innerHash: String
    }

    private struct AuthVector {
        let entry: String
        let preimage: String
        let payloadHash: String
    }

    private let v1Vectors = [
        // memo ff fe 20 61 62 63
        EnvelopeVector(envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAABAAAABv/+IGFiYwAAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
                       hash: "afd8d9d1020027a501b4e3548523f60fdfc093b163a1a77a801514342bf9d1d9"),
        // memo ef bb bf 61
        EnvelopeVector(envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAABAAAABO+7v2EAAAABAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
                       hash: "d7cce4ebcf4c7aea1a94d145eb72eb1f6c31dcecf51e390aa43de916cdb00cfd"),
        // memo ef bb bf ef bb bf 61
        EnvelopeVector(envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAABAAAAB++7v++7v2EAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
                       hash: "2a31d6472d0ee51764dd708a52fe149a83d11bc10e5ce8b9bfaa24158a90be22"),
        // memo of 28 bytes cut inside c3 a9
        EnvelopeVector(envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAABAAAAHGFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYcMAAAABAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
                       hash: "d99b04f76b7b09b523d59db35089e6256956d8fa89d4c2fdf00005a72ac182ea"),
        // memo of 28 bytes cut inside e2 82 ac
        EnvelopeVector(envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAABAAAAHGFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFh4oIAAAABAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
                       hash: "f2b1f6b938c090f68c163a71a0db74cb116ed2c7e28ef7a2e348077986224c9c"),
        // SCV_STRING argument ef bb bf 61
        EnvelopeVector(envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAFmAAAAAAAAAQAAAA4AAAAE77u/YQAAAAAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
                       hash: "600608e5230c782b6385972888e34013ee0519031d5c0798cd32a55b9c164284"),
        // SCV_SYMBOL argument ef bb bf 61
        EnvelopeVector(envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAFmAAAAAAAAAQAAAA8AAAAE77u/YQAAAAAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
                       hash: "9db200d7e94f46e9b46a3b09b8e99363939ea8fff5d8f6fd988ce8f949f0eb0c"),
        // function name ef bb bf 61
        EnvelopeVector(envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAATvu79hAAAAAAAAAAAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
                       hash: "785e5a36182816ff9a2131446efd3b85e16cce555918d53a1d009ad00735d778"),
        // SCV_STRING argument ff fe 20 61 62 63
        EnvelopeVector(envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAFmAAAAAAAAAQAAAA4AAAAG//4gYWJjAAAAAAAAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
                       hash: "d2271e8683ce85e52efbd45c6a2dbb1dac3ca61b16f4f36d8823b56486621b8c"),
        // function name ff fe 20 61 62 63
        EnvelopeVector(envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAb//iBhYmMAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
                       hash: "649e93a7e8a22e665be43f4850951f53ea8104949f60f121889d77a206976a4b"),
        // testnet transaction b7fb286b, memo ff fe 20 61 62 63
        EnvelopeVector(envelope: "AAAAAgAAAAB9dKGOpM7ReVg9puIJUE41Q4ixcNzQmY1RuqqEPX5PMAAAA+gAWPV9AAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAb//iBhYmMAAAAAAAEAAAAAAAAAAQAAAACkQeBd9iE/juL6rqj0VVFw2v8aYlIFPrDcDVEpm7RX1AAAAAAAAAAAAJiWgAAAAAAAAAABPX5PMAAAAEAqERgvj65qzoHGjnHgWnfheLjxKwOqWTLzvu/v3OwwOi2Qkejhk2V7ODCcq9/yVZ0M6rvDcOIIUrlecenAIGYP",
                       hash: "b7fb286bcb380d0f3b9ace77c8b513cc348e89805ddf16a076f2085ee8dc0816"),
    ]

    private let v0Vectors = [
        // memo ff fe 20 61 62 63
        V0Vector(envelope: "AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAZAAAAAEAAAABAAAAAAAAAAEAAAAG//4gYWJjAAAAAAABAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
                 v1Envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAABAAAABv/+IGFiYwAAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
                 fee: 100,
                 hash: "afd8d9d1020027a501b4e3548523f60fdfc093b163a1a77a801514342bf9d1d9"),
        // memo ef bb bf 61
        V0Vector(envelope: "AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAZAAAAAEAAAABAAAAAAAAAAEAAAAE77u/YQAAAAEAAAAAAAAAAQAAAAAhIiMkJSYnKCkqKywtLi8wMTIzNDU2Nzg5Ojs8PT4/QAAAAAAAAAAAAJiWgAAAAAAAAAABAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
                 v1Envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAABAAAABO+7v2EAAAABAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
                 fee: 100,
                 hash: "d7cce4ebcf4c7aea1a94d145eb72eb1f6c31dcecf51e390aa43de916cdb00cfd"),
        // memo ef bb bf ef bb bf 61
        V0Vector(envelope: "AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAZAAAAAEAAAABAAAAAAAAAAEAAAAH77u/77u/YQAAAAABAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
                 v1Envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAABAAAAB++7v++7v2EAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
                 fee: 100,
                 hash: "2a31d6472d0ee51764dd708a52fe149a83d11bc10e5ce8b9bfaa24158a90be22"),
        // two payments, fee 200, memo ff fe 20 61 62 63
        V0Vector(envelope: "AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAyAAAAAEAAAABAAAAAAAAAAEAAAAG//4gYWJjAAAAAAACAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAhIiMkJSYnKCkqKywtLi8wMTIzNDU2Nzg5Ojs8PT4/QAAAAAAAAAAAATEtAAAAAAAAAAABAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
                 v1Envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAMgAAAABAAAAAQAAAAAAAAABAAAABv/+IGFiYwAAAAAAAgAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAAExLQAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
                 fee: 200,
                 hash: "f5bb99c62173175876a0f612a712addc62dc5193fafa55553fb73cb364637abd"),
        // time bounds 0 to 1767225600, memo ff fe 20 61 62 63
        V0Vector(envelope: "AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAZAAAAAEAAAABAAAAAQAAAAAAAAAAAAAAAGlVuQAAAAABAAAABv/+IGFiYwAAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
                 v1Envelope: "AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAEAAAAAAAAAAAAAAABpVbkAAAAAAQAAAAb//iBhYmMAAAAAAAEAAAAAAAAAAQAAAAAhIiMkJSYnKCkqKywtLi8wMTIzNDU2Nzg5Ojs8PT4/QAAAAAAAAAAAAJiWgAAAAAAAAAABAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
                 fee: 100,
                 hash: "2da74931f32d2c36c3420a401105d1ac797a81a103d75fefba1155b6fef1b4b7"),
    ]

    /// The signature payload of core for a V0 vector and its hash.
    private let v0SignaturePayloads: [(payload: String, hash: String)] = [
        // two payments, fee 200, memo ff fe 20 61 62 63
        ("zuAwLVmETTK9ypFcggPdRLM/u37cGQUeo3q+3yjs1HIAAAACAAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAyAAAAAEAAAABAAAAAAAAAAEAAAAG//4gYWJjAAAAAAACAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAhIiMkJSYnKCkqKywtLi8wMTIzNDU2Nzg5Ojs8PT4/QAAAAAAAAAAAATEtAAAAAAA=",
         "f5bb99c62173175876a0f612a712addc62dc5193fafa55553fb73cb364637abd"),
        // time bounds 0 to 1767225600, memo ff fe 20 61 62 63
        ("zuAwLVmETTK9ypFcggPdRLM/u37cGQUeo3q+3yjs1HIAAAACAAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAZAAAAAEAAAABAAAAAQAAAAAAAAAAAAAAAGlVuQAAAAABAAAABv/+IGFiYwAAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAA==",
         "2da74931f32d2c36c3420a401105d1ac797a81a103d75fefba1155b6fef1b4b7"),
    ]

    private let feeBumpVectors = [
        // memo ff fe 20 61 62 63
        FeeBumpVector(envelope: "AAAABQAAAABhYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5ent8fX5/gAAAAAAAAAGQAAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAABAAAABv/+IGFiYwAAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
                      hash: "d8db2bb148d0a5b11885818541b9abe4bc44e3ad43de5e64a3b74bea2c748537",
                      innerHash: "afd8d9d1020027a501b4e3548523f60fdfc093b163a1a77a801514342bf9d1d9"),
        // memo ef bb bf 61
        FeeBumpVector(envelope: "AAAABQAAAABhYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5ent8fX5/gAAAAAAAAAGQAAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAABAAAABO+7v2EAAAABAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
                      hash: "d50d964ee0e4ded79a0c8a527438daac87685040c8456c603cc709d5e0877c0e",
                      innerHash: "d7cce4ebcf4c7aea1a94d145eb72eb1f6c31dcecf51e390aa43de916cdb00cfd"),
        // memo ef bb bf ef bb bf 61
        FeeBumpVector(envelope: "AAAABQAAAABhYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5ent8fX5/gAAAAAAAAAGQAAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAABAAAAB++7v++7v2EAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
                      hash: "34e6f71d40bf353d481cd37a493d78a4153eb7d163490093cb120ae6b56892c7",
                      innerHash: "2a31d6472d0ee51764dd708a52fe149a83d11bc10e5ce8b9bfaa24158a90be22"),
    ]

    /// Authorization entries with nonce 1234567 and expiration ledger 1000, their testnet
    /// preimages and the hashes a signer signs.
    private let authVectors = [
        // function name ef bb bf 61
        AuthVector(entry: "AAAAAQAAAAAAAAAAgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6AAAAAAABLWhwAAA+gAAAABAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAATvu79hAAAAAAAAAAA=",
                   preimage: "AAAACc7gMC1ZhE0yvcqRXIID3USzP7t+3BkFHqN6vt8o7NRyAAAAAAAS1ocAAAPoAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAATvu79hAAAAAAAAAAA=",
                   payloadHash: "b7e14047c0a7289fcd94da522ddaab04acd063db75e3b4a5189e352ba0ec84a6"),
        // transfer with SCV_STRING ef bb bf 61
        AuthVector(entry: "AAAAAQAAAAAAAAAAgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6AAAAAAABLWhwAAA+gAAAABAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAh0cmFuc2ZlcgAAAAEAAAAOAAAABO+7v2EAAAAA",
                   preimage: "AAAACc7gMC1ZhE0yvcqRXIID3USzP7t+3BkFHqN6vt8o7NRyAAAAAAAS1ocAAAPoAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAh0cmFuc2ZlcgAAAAEAAAAOAAAABO+7v2EAAAAA",
                   payloadHash: "f2319301b2ced3a8dcf2dc6d044ad8f1949e5ee3233aa5417b8d2e646636c3a5"),
        // function name ff fe 20 61 62 63
        AuthVector(entry: "AAAAAQAAAAAAAAAAgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6AAAAAAABLWhwAAA+gAAAABAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAb//iBhYmMAAAAAAAAAAAAA",
                   preimage: "AAAACc7gMC1ZhE0yvcqRXIID3USzP7t+3BkFHqN6vt8o7NRyAAAAAAAS1ocAAAPoAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAb//iBhYmMAAAAAAAAAAAAA",
                   payloadHash: "d0a19f113ebb858c5459673806b3ec674fe893f60b0cb0fa731fc497c6d24d99"),
        // transfer with SCV_STRING ff fe 20 61 62 63
        AuthVector(entry: "AAAAAQAAAAAAAAAAgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6AAAAAAABLWhwAAA+gAAAABAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAh0cmFuc2ZlcgAAAAEAAAAOAAAABv/+IGFiYwAAAAAAAA==",
                   preimage: "AAAACc7gMC1ZhE0yvcqRXIID3USzP7t+3BkFHqN6vt8o7NRyAAAAAAAS1ocAAAPoAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAh0cmFuc2ZlcgAAAAEAAAAOAAAABv/+IGFiYwAAAAAAAA==",
                   payloadHash: "85a9809802da0bc78328f29b3a6671f7b67732ae79f4e3697b0b56bdc4690c33"),
    ]

    // MARK: - XDR layer

    func testV1EnvelopesReEncodeByteForByte() throws {
        for vector in v1Vectors {
            let envelope = try TransactionEnvelopeXDR(fromBase64: vector.envelope)
            XCTAssertEqual(envelope.xdrEncoded, vector.envelope)
            XCTAssertEqual(try envelope.txHash(network: .testnet).base16EncodedString(), vector.hash)
        }
    }

    func testV0EnvelopesReEncodeByteForByte() throws {
        for vector in v0Vectors {
            let envelope = try TransactionEnvelopeXDR(fromBase64: vector.envelope)
            XCTAssertEqual(envelope.xdrEncoded, vector.envelope)
            XCTAssertEqual(try envelope.txHash(network: .testnet).base16EncodedString(), vector.hash)
        }
        for vector in v0SignaturePayloads {
            XCTAssertEqual(try XCTUnwrap(Data(base64Encoded: vector.payload)).sha256Hash.base16EncodedString(), vector.hash)
        }
    }

    func testFeeBumpEnvelopesKeepOuterAndInnerHashes() throws {
        for vector in feeBumpVectors {
            let envelope = try TransactionEnvelopeXDR(fromBase64: vector.envelope)
            XCTAssertEqual(envelope.xdrEncoded, vector.envelope)
            guard case .feeBump(let feeBump) = envelope else {
                return XCTFail("expected a fee bump envelope")
            }
            XCTAssertEqual(try feeBump.tx.hash(network: .testnet).base16EncodedString(), vector.hash)
            XCTAssertEqual(try envelope.txHash(network: .testnet).base16EncodedString(), vector.innerHash)
        }
    }

    func testAuthorizationPreimagesKeepTheBytes() throws {
        for vector in authVectors {
            let entry = try SorobanAuthorizationEntryXDR(fromBase64: vector.entry)
            XCTAssertEqual(entry.xdrEncoded, vector.entry)
            let preimage = try entry.buildPreimage(network: .testnet)
            XCTAssertEqual(preimage.xdrEncoded, vector.preimage)
            XCTAssertEqual(Data(try XDREncoder.encode(preimage)).sha256Hash.base16EncodedString(), vector.payloadHash)
        }
    }

    // MARK: - Transaction import

    private let inflationV1Envelope = "AAAAAgAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAGQAAAAAAAHUwQAAAAAAAAAAAAAAAQAAAAAAAAAJAAAAAAAAAAA="
    private let inflationTestnetHash = "f945e9bb73f4cb635b8b192874d39f8d99ced394c64db42bbec2dd7af867998d"

    func testInflationV1ImportKeepsEnvelopeAndHashes() throws {
        let transaction = try Transaction(envelopeXdr: inflationV1Envelope)
        XCTAssertEqual(transaction.operations.count, 1)
        XCTAssertTrue(try XCTUnwrap(transaction.operations.first) is InflationOperation)
        XCTAssertEqual(try transaction.encodedEnvelope(), inflationV1Envelope)
        XCTAssertEqual(try transaction.getTransactionHash(network: .testnet), inflationTestnetHash)
        XCTAssertEqual(try transaction.getTransactionHash(network: .public),
                       "797002f6f64ec5c7d0ce624a1eae82d5101c7dff547bbf12285baff13b45a99f")
    }

    func testInflationV0ImportWritesV1AndKeepsHash() throws {
        let input = "AAAAALskC4Tde+q46duyC/ZJHO2O6ThGgFV59DSuWsUwxC98AAAAZAAAAAAAAdTBAAAAAAAAAAAAAAABAAAAAAAAAAkAAAAAAAAAAA=="
        let transaction = try Transaction(envelopeXdr: input)
        XCTAssertTrue(try XCTUnwrap(transaction.operations.first) is InflationOperation)
        XCTAssertEqual(try transaction.getTransactionHash(network: .testnet), inflationTestnetHash)
        XCTAssertEqual(try transaction.encodedEnvelope(), inflationV1Envelope)
    }

    func testInflationFeeBumpImportKeepsEnvelopeAndHashes() throws {
        let input = "AAAABQAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAAAAAADIAAAAAgAAAAC7JAuE3XvquOnbsgv2SRztjuk4RoBVefQ0rlrFMMQvfAAAAGQAAAAAAAHUwQAAAAAAAAAAAAAAAQAAAAAAAAAJAAAAAAAAAAAAAAAAAAAAAA=="
        let transaction = try FeeBumpTransaction(envelopeXdr: input)
        XCTAssertTrue(try XCTUnwrap(transaction.innerTransaction.operations.first) is InflationOperation)
        XCTAssertEqual(try transaction.getTransactionHash(network: .testnet),
                       "1e2c7089c9035f1f5869db1dc6cf9a9234affe389d3fbbb5a56cebd6ef16f658")
        XCTAssertEqual(try transaction.innerTransaction.getTransactionHash(network: .testnet), inflationTestnetHash)
        XCTAssertEqual(try transaction.encodedEnvelope(), input)
    }

    func testInflationTransactionBodyImportKeepsHash() throws {
        guard case .v1(let envelope) = try TransactionEnvelopeXDR(fromBase64: inflationV1Envelope) else {
            return XCTFail("expected a V1 envelope")
        }
        let transaction = try Transaction(xdr: XCTUnwrap(envelope.tx.xdrEncoded))
        XCTAssertTrue(try XCTUnwrap(transaction.operations.first) is InflationOperation)
        XCTAssertEqual(try transaction.getTransactionHash(network: .testnet), inflationTestnetHash)
    }

    func testV1ImportKeepsTheEnvelopeAndTheHash() throws {
        for vector in v1Vectors {
            let transaction = try Transaction(envelopeXdr: vector.envelope)
            XCTAssertEqual(try transaction.encodedEnvelope(), vector.envelope)
            XCTAssertEqual(try transaction.getTransactionHash(network: .testnet), vector.hash)

            guard case .v1(let envelopeV1) = try TransactionEnvelopeXDR(fromBase64: vector.envelope) else {
                return XCTFail("expected a V1 envelope")
            }
            let body = try XCTUnwrap(envelopeV1.tx.xdrEncoded)
            let imported = try Transaction(xdr: body)
            XCTAssertEqual(imported.transactionXDR.xdrEncoded, body)
            XCTAssertEqual(try imported.getTransactionHash(network: .testnet), vector.hash)
        }
    }

    func testV0ImportGivesTheV1FormWithTheSameHash() throws {
        for vector in v0Vectors {
            let transaction = try Transaction(envelopeXdr: vector.envelope)
            XCTAssertEqual(transaction.fee, vector.fee)
            XCTAssertEqual(transaction.transactionXDR.fee, vector.fee)
            XCTAssertEqual(try transaction.encodedEnvelope(), vector.v1Envelope)
            XCTAssertEqual(try transaction.getTransactionHash(network: .testnet), vector.hash)
        }
    }

    func testFeeBumpImportGivesTheInnerTransaction() throws {
        for vector in feeBumpVectors {
            guard case .feeBump(let feeBump) = try TransactionEnvelopeXDR(fromBase64: vector.envelope),
                  case .v1(let inner) = feeBump.tx.innerTx else {
                return XCTFail("expected a fee bump envelope")
            }
            let transaction = try Transaction(envelopeXdr: vector.envelope)
            XCTAssertEqual(try transaction.getTransactionHash(network: .testnet), vector.innerHash)
            XCTAssertEqual(transaction.transactionXDR.signatures.map { $0.xdrEncoded }, inner.signatures.map { $0.xdrEncoded })
            XCTAssertEqual(try transaction.encodedEnvelope(), TransactionEnvelopeXDR.v1(inner).xdrEncoded)
        }
    }

    func testSignatureAfterImportCoversTheInputHash() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let inputs = v1Vectors.map { ($0.envelope, $0.hash) } + v0Vectors.map { ($0.envelope, $0.hash) }
            + feeBumpVectors.map { ($0.envelope, $0.innerHash) }
        for (envelope, hash) in inputs {
            let transaction = try Transaction(envelopeXdr: envelope)
            let signatureCount = transaction.transactionXDR.signatures.count
            try transaction.sign(keyPair: keyPair, network: .testnet)
            XCTAssertEqual(transaction.transactionXDR.signatures.count, signatureCount + 1)
            let signature = try XCTUnwrap(transaction.transactionXDR.signatures.last)
            XCTAssertTrue(try keyPair.verify(signature: [UInt8](signature.signature), message: [UInt8](try Data(base16Encoded: hash))))
        }
    }

    func testTxRepRoundTripKeepsTheBytes() throws {
        let memoEnvelope = try XCTUnwrap(v1Vectors.first).envelope
        let txRep = try TxRep.toTxRep(transactionEnvelope: memoEnvelope)
        XCTAssertTrue(txRep.contains(#"tx.memo.text: "\xff\xfe abc""#), txRep)
        let stringTxRep = try TxRep.toTxRep(transactionEnvelope: try XCTUnwrap(v1Vector(hash: "d2271e8683ce85e52efbd45c6a2dbb1dac3ca61b16f4f36d8823b56486621b8c")).envelope)
        XCTAssertTrue(stringTxRep.contains(#".args[0].str: "\xff\xfe abc""#), stringTxRep)
        let nameTxRep = try TxRep.toTxRep(transactionEnvelope: try XCTUnwrap(v1Vector(hash: "649e93a7e8a22e665be43f4850951f53ea8104949f60f121889d77a206976a4b")).envelope)
        XCTAssertTrue(nameTxRep.contains(#".invokeContract.functionName: "\xff\xfe abc""#), nameTxRep)
        for vector in v1Vectors {
            XCTAssertEqual(try TxRep.fromTxRep(txRep: try TxRep.toTxRep(transactionEnvelope: vector.envelope)), vector.envelope)
        }
    }

    // MARK: - Valid input that the import now keeps

    func testImportKeepsAFeeThatIsNotAMultipleOfTheOperationCount() throws {
        var transactionXDR = try makeTransactionXDR(operations: [try payment(), try payment()])
        transactionXDR.fee = 301
        let envelope = try XCTUnwrap(try transactionXDR.toEnvelopeXDR().xdrEncoded)
        let body = try XCTUnwrap(transactionXDR.xdrEncoded)
        let hash = try transactionXDR.hash(network: .testnet).base16EncodedString()

        for transaction in [try Transaction(envelopeXdr: envelope), try Transaction(xdr: body)] {
            XCTAssertEqual(transaction.fee, 301)
            XCTAssertEqual(transaction.transactionXDR.fee, 301)
            XCTAssertEqual(try transaction.getTransactionHash(network: .testnet), hash)
        }
        let transaction = try Transaction(envelopeXdr: envelope)
        XCTAssertEqual(try transaction.encodedEnvelope(), envelope)
        transaction.addResourceFee(resourceFee: 1)
        XCTAssertEqual(transaction.fee, 302)
        XCTAssertEqual(transaction.transactionXDR.fee, 302)
    }

    func testImportKeepsASignerWeightAboveTwoHundredFiftyFive() throws {
        let signer = SignerXDR(key: .ed25519(WrappedData32(Data(repeating: 9, count: 32))), weight: 256)
        let setOptions = OperationXDR(body: .setOptionsOp(SetOptionsOperationXDR(signer: signer)))
        let transactionXDR = try makeTransactionXDR(operations: [setOptions])
        let envelope = try XCTUnwrap(try transactionXDR.toEnvelopeXDR().xdrEncoded)

        let transaction = try Transaction(envelopeXdr: envelope)
        XCTAssertEqual(transaction.transactionXDR.operations.first?.xdrEncoded, setOptions.xdrEncoded)
        XCTAssertEqual(try transaction.encodedEnvelope(), envelope)
    }

    func testImportKeepsSequenceHandlingAndValidation() throws {
        let transactionXDR = try makeTransactionXDR(operations: [try payment()], seqNum: 4294967298)
        let transaction = try Transaction(envelopeXdr: try XCTUnwrap(try transactionXDR.toEnvelopeXDR().xdrEncoded))
        XCTAssertEqual(transaction.sourceAccount.sequenceNumber, 4294967298)

        let empty = try makeTransactionXDR(operations: [])
        let noOperation = "At least one operation required"
        assertInvalidArgument(try Transaction(envelopeXdr: try XCTUnwrap(try empty.toEnvelopeXDR().xdrEncoded)), noOperation)
        assertInvalidArgument(try Transaction(xdr: try XCTUnwrap(empty.xdrEncoded)), noOperation)
        let minimum = try makeTransactionXDR(operations: [try payment()], seqNum: Int64.min)
        let noPrecedingSequence = "Invalid transaction sequence number \(Int64.min): no account sequence number precedes it"
        assertInvalidArgument(try Transaction(envelopeXdr: try XCTUnwrap(try minimum.toEnvelopeXDR().xdrEncoded)), noPrecedingSequence)
        assertInvalidArgument(try Transaction(xdr: try XCTUnwrap(minimum.xdrEncoded)), noPrecedingSequence)
    }

    private func assertInvalidArgument(_ expression: @autoclosure () throws -> Transaction, _ message: String,
                                       file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            guard case StellarSDKError.invalidArgument(let text) = error else {
                return XCTFail("wrong error: \(error)", file: file, line: line)
            }
            XCTAssertEqual(text, message, file: file, line: line)
        }
    }

    /// Every operation of the XDR corpus inside a one-operation V1 envelope: the import gives
    /// the input bytes and the hash of the input.
    func testCorpusOperationsImportToTheirInputBytes() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "corpus", withExtension: "json"))
        let corpus = try JSONDecoder().decode(OperationCorpus.self, from: Data(contentsOf: url))
        let operationEntries = corpus.entries.filter { $0.type == "Operation" || $0.type == "OperationBody" }
        for entry in operationEntries {
            let bytes = [UInt8](try XCTUnwrap(Data(base64Encoded: entry.xdr)))
            let operationXDR = entry.type == "Operation"
                ? try XDRDecoder.decode(OperationXDR.self, data: bytes)
                : OperationXDR(body: try XDRDecoder.decode(OperationBodyXDR.self, data: bytes))
            let transactionXDR = try makeTransactionXDR(operations: [operationXDR])
            let envelope = try XCTUnwrap(try transactionXDR.toEnvelopeXDR().xdrEncoded)
            let body = try XCTUnwrap(transactionXDR.xdrEncoded)
            let hash = (Data(Network.testnet.networkId) + Data([0, 0, 0, 2]) + Data(try XDREncoder.encode(transactionXDR)))
                .sha256Hash.base16EncodedString()

            do {
                for transaction in [try Transaction(envelopeXdr: envelope), try Transaction(xdr: body)] {
                    XCTAssertEqual(transaction.transactionXDR.xdrEncoded, body, entry.json)
                    XCTAssertEqual(try transaction.getTransactionHash(network: .testnet), hash, entry.json)
                }
                XCTAssertEqual(try Transaction(envelopeXdr: envelope).encodedEnvelope(), envelope, entry.json)
            } catch {
                XCTFail("\(entry.json): the import failed with \(error)")
            }
        }
        XCTAssertGreaterThan(operationEntries.count, 0)
    }

    // MARK: - Raw memo reuse

    func testRawMemoReuseKeepsTheBytes() throws {
        let memo = try TransactionEnvelopeXDR(fromBase64: try XCTUnwrap(v1Vectors.first).envelope).txMemo
        let reuseTransaction = "AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAZAAAAAEAAAACAAAAAAAAAAEAAAAG//4gYWJjAAAAAAABAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAA"
        let reuseHash = "ce8dc489b022120d067cbcb122623d2770113fe6dc5b04efe3ff38d6221d859f"

        let transaction = try Transaction(sourceAccount: try account(sequenceNumber: 4294967297), operations: [try paymentOperation()], memo: nil)
        transaction.setMemo(memoXDR: memo)
        XCTAssertEqual(transaction.transactionXDR.xdrEncoded, reuseTransaction)
        XCTAssertEqual(try transaction.getTransactionHash(network: .testnet), reuseHash)
        XCTAssertEqual(transaction.memo, Memo.text("\u{FFFD}\u{FFFD} abc"))

        let built = try Transaction(sourceAccount: try account(sequenceNumber: 4294967297), operations: [try paymentOperation()], memoXDR: memo)
        XCTAssertEqual(built.transactionXDR.xdrEncoded, reuseTransaction)
        XCTAssertEqual(try built.getTransactionHash(network: .testnet), reuseHash)
        XCTAssertEqual(built.memo, Memo.text("\u{FFFD}\u{FFFD} abc"))

        // The display memo writes its replacement characters, not the original bytes.
        transaction.setMemo(memo: transaction.memo)
        XCTAssertEqual(transaction.transactionXDR.memo.xdrEncoded,
                       MemoXDR.text(Data([0xef, 0xbf, 0xbd, 0xef, 0xbf, 0xbd, 0x20, 0x61, 0x62, 0x63])).xdrEncoded)
    }

    // MARK: - Helpers

    private func v1Vector(hash: String) -> EnvelopeVector? {
        return v1Vectors.first { $0.hash == hash }
    }

    private struct OperationCorpus: Decodable {
        let entries: [Entry]

        struct Entry: Decodable {
            let type: String
            let xdr: String
            let json: String
        }
    }

    /// The source account of the vectors: the public key of the bytes 1 to 32.
    private func sourceKeyPair() throws -> KeyPair {
        return KeyPair(publicKey: try PublicKey([UInt8](1...32)))
    }

    private func account(sequenceNumber: Int64) throws -> Account {
        return Account(keyPair: try sourceKeyPair(), sequenceNumber: sequenceNumber)
    }

    /// A payment of 1 XLM to the public key of the bytes 33 to 64, as in the vectors.
    private func paymentOperation() throws -> PaymentOperation {
        let destination = KeyPair(publicKey: try PublicKey([UInt8](33...64)))
        return try PaymentOperation(sourceAccountId: nil, destinationAccountId: destination.accountId,
                                    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 1)
    }

    private func payment() throws -> OperationXDR {
        return try paymentOperation().toXDR()
    }

    private func makeTransactionXDR(operations: [OperationXDR], seqNum: Int64 = 5) throws -> TransactionXDR {
        return TransactionXDR(sourceAccount: try sourceKeyPair().publicKey, seqNum: seqNum, cond: .none,
                              memo: .none, operations: operations, maxOperationFee: 100)
    }
}
