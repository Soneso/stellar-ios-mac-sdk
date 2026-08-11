//
//  Sep51CanonicalEnvelopeUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// The full `TransactionEnvelope` example of SEP-0051 §Examples, pinned in both directions.
///
/// The two directions are deliberately asserted differently. Reading the specification's
/// document compares **structure**: the document is pretty-printed, so any byte comparison
/// would fail for reasons that have nothing to do with the mapping, while a tree comparison
/// still pins every key, every key order and every value. Writing compares **bytes**: the
/// document must re-encode to the exact binary the specification prints beside it, which is
/// the only assertion that can catch a value read into the wrong field.
///
/// The example exercises a nested envelope union, an operation array, a void arm rendered as
/// a bare string, an absent optional, an empty array, a contract strkey, hyper integers, hex
/// signatures and an integer-cased extension union, so it is the broadest single fixture the
/// specification provides.
///
/// `XdrJsonParser` is internal, so this suite reaches it with a testable import. The
/// structural direction needs a tree built from the specification's own text rather than one
/// built by this SDK, or it would compare the emitter against itself.
final class Sep51CanonicalEnvelopeUnitTests: XCTestCase {

    // MARK: - Reading the specification document

    func testSpecificationEnvelopeRendersTheDocumentedStructure() throws {
        let envelope = try XDRDecoder.decode(TransactionEnvelopeXDR.self,
                                             data: try Self.data(Self.envelopeBase64))
        let produced = try envelope.toXdrJsonValue()
        let documented = try XdrJsonParser.parse(Self.envelopeJson)

        XCTAssertEqual(produced, documented,
                       "the rendered tree differs from the SEP-0051 §Examples document")
    }

    func testSpecificationEnvelopeKeepsDeclarationOrderThroughEveryLevel() throws {
        let envelope = try XDRDecoder.decode(TransactionEnvelopeXDR.self,
                                             data: try Self.data(Self.envelopeBase64))
        let tx = try XCTUnwrap(try envelope.toXdrJsonValue().member("tx")?.member("tx"))

        guard case .object(let members) = tx else {
            return XCTFail("the inner transaction is not a JSON object")
        }
        XCTAssertEqual(members.map(\.key),
                       ["source_account", "fee", "seq_num", "cond", "memo", "operations", "ext"])
    }

    // MARK: - Writing the binary back

    func testSpecificationEnvelopeDocumentReadsBackToTheDocumentedBase64() throws {
        let envelope = try TransactionEnvelopeXDR.fromXdrJson(Self.envelopeJson)
        XCTAssertEqual(Data(try XDREncoder.encode(envelope)).base64EncodedString(),
                       Self.envelopeBase64,
                       "the SEP-0051 §Examples document does not re-encode to its documented binary")
    }

    func testCanonicalTextOfTheSpecificationEnvelopeReadsBackToTheSameBinary() throws {
        let envelope = try XDRDecoder.decode(TransactionEnvelopeXDR.self,
                                             data: try Self.data(Self.envelopeBase64))
        let canonical = try envelope.toXdrJson()

        XCTAssertFalse(canonical.contains("\n"), "canonical output is a single line")
        XCTAssertFalse(canonical.contains(": "), "canonical output carries no insignificant whitespace")

        let read = try TransactionEnvelopeXDR.fromXdrJson(canonical)
        XCTAssertEqual(Data(try XDREncoder.encode(read)).base64EncodedString(), Self.envelopeBase64)
        XCTAssertEqual(try read.toXdrJson(), canonical)
    }

    // MARK: - Fixtures

    private static let envelopeBase64 =
        "AAAAAgAAAADmmSZkwY3163TMouB2TY8MljqXw2IxVYTGyvDrR6YtAAAqmmQAABpuAAAAAQAAAAAAAAAAAAAA"
        + "AQAAAAAAAAAYAAAAAQAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAABAAAABgAAAAHXkotywnA8z+r3"
        + "65/0701QSlWouXn8m0UOoshCtNHOYQAAABQAAAABAAI9fQAAAAAAAAD4AAAAAAAqmgAAAAABR6YtAAAAAEAr"
        + "DtxbqUI+CsdkRmV0lFhVt0wyB7fyrmmkM6Fr35wpPcK8WKcXeKTl4BQ+akE14MZtpaea9LMdhXopaW3pJA0E"

    /// The document exactly as SEP-0051 §Examples prints it, pretty-printing included.
    private static let envelopeJson = """
    {
      "tx": {
        "tx": {
          "source_account": "GDTJSJTEYGG7L23UZSROA5SNR4GJMOUXYNRDCVMEY3FPB22HUYWQBZIA",
          "fee": 2792036,
          "seq_num": "29059748724737",
          "cond": "none",
          "memo": "none",
          "operations": [
            {
              "source_account": null,
              "body": {
                "invoke_host_function": {
                  "host_function": {
                    "create_contract": {
                      "contract_id_preimage": {
                        "asset": "native"
                      },
                      "executable": "stellar_asset"
                    }
                  },
                  "auth": []
                }
              }
            }
          ],
          "ext": {
            "v1": {
              "ext": "v0",
              "resources": {
                "footprint": {
                  "read_only": [],
                  "read_write": [
                    {
                      "contract_data": {
                        "contract": "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
                        "key": "ledger_key_contract_instance",
                        "durability": "persistent"
                      }
                    }
                  ]
                },
                "instructions": 146813,
                "disk_read_bytes": 0,
                "write_bytes": 248
              },
              "resource_fee": "2791936"
            }
          }
        },
        "signatures": [
          {
            "hint": "47a62d00",
            "signature": "2b0edc5ba9423e0ac764466574945855b74c3207b7f2ae69a433a16bdf9c293dc2bc58a71778a4e5e0143e6a4135e0c66da5a79af4b31d857a29696de9240d04"
          }
        ]
      }
    }
    """

    // MARK: - Helpers

    private static func data(_ base64: String) throws -> Data {
        try XCTUnwrap(Data(base64Encoded: base64), "not base64: \(base64)")
    }
}
