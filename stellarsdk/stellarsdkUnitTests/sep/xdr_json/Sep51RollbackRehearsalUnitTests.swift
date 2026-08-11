//
//  Sep51RollbackRehearsalUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Frozen constants that make any change to the emitted byte form a deliberate act.
///
/// Everything else in the XDR-JSON suites derives its expected value from something: the
/// specification text, the conformance corpus, or the generator's own fixtures. This suite
/// derives nothing. Two values are written down as base64 and as the exact text this SDK must
/// emit for them, and both forms are asserted verbatim in both directions.
///
/// That makes the suite the one place where a change in the wire form cannot pass unnoticed.
/// A protocol bump legitimately changes what is emitted -- SEP-0051 §Breaking Changes says an
/// XDR structural change is not a specification change -- so this failing is not by itself a
/// defect. It is the signal that the new form has to be reviewed, the constants replaced, and
/// the change written into the release notes before it reaches a consumer whose stored
/// documents were produced by the previous release.
///
/// The envelope crosses as much of the classic mapping as one value can: a muxed source
/// account, an unsigned 32-bit fee beside 64-bit values written as strings, time bounds behind
/// a precondition union, a memo whose text carries a byte the escape ladder rewrites, an
/// operation with an absent optional source and one with a present one, a four-character asset
/// code, several null optionals in a row, and a hexadecimal signature.
///
/// The contract value covers the Soroban half, which the envelope does not reach and which a
/// protocol bump is the most likely to move: the four wide-integer types at their extremes, a
/// contract address as a `C…` strkey, an empty vector and an empty map, a symbol and an empty
/// symbol, empty variable-length opaque data, a void arm as a bare string, and a string.
final class Sep51RollbackRehearsalUnitTests: XCTestCase {

    // MARK: - The frozen envelope

    func testFrozenEnvelopeRendersTheFrozenJson() throws {
        let envelope = try XDRDecoder.decode(TransactionEnvelopeXDR.self,
                                             data: try Self.data(Self.envelopeBase64))

        XCTAssertEqual(try envelope.toXdrJson(), Self.envelopeJson,
                       Self.rehearsalMessage(for: "envelope"))
    }

    func testFrozenJsonReadsBackToTheFrozenEnvelope() throws {
        let envelope = try TransactionEnvelopeXDR.fromXdrJson(Self.envelopeJson)

        XCTAssertEqual(Data(try XDREncoder.encode(envelope)).base64EncodedString(),
                       Self.envelopeBase64, Self.rehearsalMessage(for: "envelope"))
    }

    func testFrozenFormIsStableAcrossARoundTrip() throws {
        let envelope = try TransactionEnvelopeXDR.fromXdrJson(Self.envelopeJson)
        let rendered = try envelope.toXdrJson()

        XCTAssertEqual(rendered, Self.envelopeJson, Self.rehearsalMessage(for: "envelope"))
        XCTAssertEqual(try TransactionEnvelopeXDR.fromXdrJson(rendered).toXdrJson(),
                       Self.envelopeJson, Self.rehearsalMessage(for: "envelope"))
    }

    // MARK: - The frozen contract value

    func testFrozenContractValueRendersTheFrozenJson() throws {
        let value = try XDRDecoder.decode(SCValXDR.self,
                                          data: try Self.data(Self.contractValueBase64))

        XCTAssertEqual(try value.toXdrJson(), Self.contractValueJson,
                       Self.rehearsalMessage(for: "contract value"))
    }

    func testFrozenJsonReadsBackToTheFrozenContractValue() throws {
        let value = try SCValXDR.fromXdrJson(Self.contractValueJson)

        XCTAssertEqual(Data(try XDREncoder.encode(value)).base64EncodedString(),
                       Self.contractValueBase64, Self.rehearsalMessage(for: "contract value"))
    }

    func testFrozenContractValueFormIsStableAcrossARoundTrip() throws {
        let value = try SCValXDR.fromXdrJson(Self.contractValueJson)
        let rendered = try value.toXdrJson()

        XCTAssertEqual(rendered, Self.contractValueJson,
                       Self.rehearsalMessage(for: "contract value"))
        XCTAssertEqual(try SCValXDR.fromXdrJson(rendered).toXdrJson(), Self.contractValueJson,
                       Self.rehearsalMessage(for: "contract value"))
    }

    // MARK: - Constants

    private static func rehearsalMessage(for subject: String) -> String {
        """
        The emitted XDR-JSON form of this \(subject) has changed. If the change is intended, \
        replace both of its constants in Sep51RollbackRehearsalUnitTests with the new pair and \
        record the change in the release notes: documents produced by the previous release will \
        not match the new form.
        """
    }

    private static let envelopeBase64 =
        "AAAAAgAAAQAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB9AAAAAMAAAABAAAA"
        + "AQAAAABlU/EAAAAAAGVT/xAAAAABAAAACHRhZwl0ZXN0AAAAAgAAAAAAAAABAAAAAOaZJmTBjfXrdMyi4HZN"
        + "jwyWOpfDYjFVhMbK8OtHpi0AAAAAAVVTRAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        + "AAAAO5rKAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFAAAAAAAAAAAAAAAB"
        + "AAAAAQAAAAAAAAAAAAAAAAAAAAAAAAABAAAACnNvbmVzby5jb20AAAAAAAAAAAAAAAAAAUemLQAAAABAKw7c"
        + "W6lCPgrHZEZldJRYVbdMMge38q5ppDOha9+cKT3CvFinF3ik5eAUPmpBNeDGbaWnmvSzHYV6KWlt6SQNBA=="

    private static let envelopeJson =
        #"{"tx":{"tx":{"source_account":"#
        + #""MAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFNZG","fee":500,"#
        + #""seq_num":"12884901889","cond":{"time":{"min_time":"1700000000","#
        + #""max_time":"1700003600"}},"memo":{"text":"tag\\ttest"},"operations":[{"#
        + #""source_account":null,"body":{"payment":{"destination":"#
        + #""GDTJSJTEYGG7L23UZSROA5SNR4GJMOUXYNRDCVMEY3FPB22HUYWQBZIA","asset":{"#
        + #""credit_alphanum4":{"asset_code":"USD","#
        + #""issuer":"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"}},"#
        + #""amount":"1000000000"}}},{"#
        + #""source_account":"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF","#
        + #""body":{"set_options":{"inflation_dest":null,"clear_flags":null,"set_flags":1,"#
        + #""master_weight":null,"low_threshold":null,"med_threshold":null,"#
        + #""high_threshold":null,"home_domain":"soneso.com","signer":null}}}],"ext":"v0"},"#
        + #""signatures":[{"hint":"47a62d00","signature":"#
        + #""2b0edc5ba9423e0ac764466574945855b74c3207b7f2ae69a433a16bdf9c293d"#
        + #"c2bc58a71778a4e5e0143e6a4135e0c66da5a79af4b31d857a29696de9240d04"}]}}"#

    private static let contractValueBase64 =
        "AAAAEAAAAAEAAAAMAAAADwAAAAh0cmFuc2ZlcgAAABIAAAABKw7cW6lCPgrHZEZldJRYVbdMMge38q5ppDOh"
        + "a9+cKT0AAAAKgAAAAAAAAAAAAAAAAAAAAAAAAAn/////////////////////AAAADIAAAAAAAAAAAAAAAAAA"
        + "AAAAAAAAAAAAAAAAAAAAAAAAAAAAC///////////////////////////////////////////AAAAEAAAAAEA"
        + "AAAAAAAAEQAAAAEAAAAAAAAADwAAAAAAAAANAAAAAAAAAAEAAAAOAAAAAm9rAAA="

    private static let contractValueJson =
        #"{"vec":[{"symbol":"transfer"},{"address":"#
        + #""CAVQ5XC3VFBD4CWHMRDGK5EULBK3OTBSA637FLTJUQZ2C267TQUT2RDQ"},{"#
        + #""i128":"-170141183460469231731687303715884105728"},{"#
        + #""u128":"340282366920938463463374607431768211455"},{"i256":"-578960446186580977117"#
        + #"85492504343953926634992332820282019728792003956564819968"},{"u256":"1157920892373"#
        + #"16195423570985008687907853269984665640564039457584007913129639935"},{"vec":[]},{"#
        + #""map":[]},{"symbol":""},{"bytes":""},"void",{"string":"ok"}]}"#

    // MARK: - Helpers

    private static func data(_ base64: String) throws -> Data {
        try XCTUnwrap(Data(base64Encoded: base64), "not base64: \(base64)")
    }
}
