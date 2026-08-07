//
//  Sep51DocTest.swift
//  stellarsdkTests
//
//  Tests for SEP-51 documentation code examples.
//  SEP-51: XDR-JSON, a mapping between XDR structures and JSON.
//

import Foundation
import XCTest
import stellarsdk

class Sep51DocTest: XCTestCase {

    let issuerAccountId = "GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI"

    let envelopeBase64 = "AAAAAgAAAAArFkuQQ4QuQY6SkLc5xxSdwpFOvl7VqKVvrfkPSqB+0AAAAGQApSmNAAAAAQAAAAEAAAAAW4nJgAAAAABdav0AAAAAAQAAABZFbmpveSB0aGlzIHRyYW5zYWN0aW9uAAAAAAABAAAAAAAAAAEAAAAAQF827djPIu+/gHK5hbakwBVRw03TjBN6yNQNQCzR97QAAAABVVNEAAAAAAAyUlQyIZKfbs+tUWuvK7N0nGSCII0/Go1/CpHXNW3tCwAAAAAX15OgAAAAAAAAAAFKoH7QAAAAQN77Tx+tHCeTJ7Va8YT9zd9z9Peoy0Dn5TSnHXOgUSS6Np23ptMbR8r9EYWSJGqFdebCSauU7Ddo3ttikiIc5Qw="

    // MARK: - Quick example: envelope to JSON and back

    func testQuickExample() throws {
        let envelope = try XDRDecoder.decode(TransactionEnvelopeXDR.self,
                                             data: Data(base64Encoded: envelopeBase64)!)

        let json = try envelope.toXdrJson()

        let restored = try TransactionEnvelopeXDR.fromXdrJson(json)
        let restoredBase64 = Data(try XDREncoder.encode(restored)).base64EncodedString()
        XCTAssertEqual(restoredBase64, envelopeBase64)

        // The document quoted in the documentation, joined back onto one line.
        let documented = #"{"tx":{"tx":{"source_account":"GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN""#
            + #","fee":100,"seq_num":"46489056724385793","cond":{"time":{"min_time":"1535756672""#
            + #","max_time":"1567292672"}},"memo":{"text":"Enjoy this transaction"},"operations":["#
            + #"{"source_account":null,"body":{"payment":{"#
            + #""destination":"GBAF6NXN3DHSF357QBZLTBNWUTABKUODJXJYYE32ZDKA2QBM2H33IK6O""#
            + #","asset":{"credit_alphanum4":{"asset_code":"USD""#
            + #","issuer":"GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI"}},"#
            + #""amount":"400004000"}}}],"ext":"v0"},"signatures":[{"hint":"4aa07ed0","#
            + #""signature":"defb4f1fad1c279327b55af184fdcddf73f4f7a8cb40e7e534a71d73a05124ba369db7a6d3"#
            + #"1b47cafd118592246a8575e6c249ab94ec3768dedb6292221ce50c"}]}}"#
        XCTAssertEqual(json, documented)
    }

    // MARK: - Converting a value to JSON

    func testConvertingAValueToJson() throws {
        let bounds = TimeBoundsXDR(minTime: 1700000000, maxTime: 1700003600)
        XCTAssertEqual(try bounds.toXdrJson(),
                       #"{"min_time":"1700000000","max_time":"1700003600"}"#)

        let asset = try AssetXDR(assetCode: "USD",
                                 issuer: try KeyPair(accountId: issuerAccountId))
        XCTAssertEqual(try asset.toXdrJson(),
                       #"{"credit_alphanum4":{"asset_code":"USD","issuer":"GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI"}}"#)

        XCTAssertEqual(try AssetXDR.native.toXdrJson(), #""native""#)
    }

    // MARK: - Working with the tree

    func testReadingOneFieldFromTheTree() throws {
        let bounds = TimeBoundsXDR(minTime: 1700000000, maxTime: 1700003600)
        let tree = try bounds.toXdrJsonValue()

        guard case .string(let minTime)? = tree.member("min_time") else {
            return XCTFail("min_time is not a string")
        }
        XCTAssertEqual(minTime, "1700000000")
    }

    func testReadingAHandBuiltTree() throws {
        let tree = XdrJsonValue.object([
            XdrJsonMember(key: "min_time", value: .string("0")),
            XdrJsonMember(key: "max_time", value: .string("1"))
        ])

        let bounds = try TimeBoundsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(bounds.minTime, 0)
        XCTAssertEqual(bounds.maxTime, 1)
    }

    // MARK: - Types that share one Swift type

    func testCodecNamespacesForCollapsedTypedefs() throws {
        let raw = WrappedData32(Data(repeating: 0x0b, count: 32))

        XCTAssertEqual(try HashXDRJsonCodec.toXdrJson(raw),
                       #""0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b""#)
        XCTAssertEqual(try ContractIDXDRJsonCodec.toXdrJson(raw),
                       #""CAFQWCYLBMFQWCYLBMFQWCYLBMFQWCYLBMFQWCYLBMFQWCYLBMFQX4KO""#)
        XCTAssertEqual(try PoolIDXDRJsonCodec.toXdrJson(raw),
                       #""LAFQWCYLBMFQWCYLBMFQWCYLBMFQWCYLBMFQWCYLBMFQWCYLBMFQXFAD""#)
    }

    func testConvertingTheEnclosingOperationRatherThanItsBody() throws {
        let documented = #"{"source_account":null,"body":{"manage_sell_offer":{"selling":"native","buying":{"credit_alphanum4":{"asset_code":"USD","issuer":"GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI"}},"amount":"7","price":{"n":1,"d":2},"offer_id":"0"}}}"#

        let operation = try OperationXDR.fromXdrJson(documented)
        XCTAssertEqual(try operation.toXdrJson(), documented)
    }

    // MARK: - Booleans

    func testBooleans() throws {
        let iterator = EvictionIteratorXDR(bucketListLevel: 3,
                                           isCurrBucket: true,
                                           bucketFileOffset: 4096)
        XCTAssertEqual(try iterator.toXdrJson(),
                       #"{"bucket_list_level":3,"is_curr_bucket":true,"bucket_file_offset":"4096"}"#)

        // Neither a string nor a number is accepted where a boolean is declared.
        for rejected in [#""true""#, "1"] {
            let json = #"{"bucket_list_level":3,"is_curr_bucket":\#(rejected),"bucket_file_offset":"4096"}"#
            XCTAssertThrowsError(try EvictionIteratorXDR.fromXdrJson(json)) { error in
                guard case XdrJsonError.unexpectedType(_, let key, let expected, _)? =
                        error as? XdrJsonError else {
                    return XCTFail("expected unexpectedType, got \(error)")
                }
                XCTAssertEqual(key, "is_curr_bucket")
                XCTAssertEqual(expected, "boolean")
            }
        }
    }

    // MARK: - 64-bit integers are strings

    func testSixtyFourBitIntegersAreStrings() throws {
        XCTAssertEqual(try LiabilitiesXDR(buying: -1, selling: 5).toXdrJson(),
                       #"{"buying":"-1","selling":"5"}"#)

        // The same holds for a 64-bit value converted on its own.
        XCTAssertEqual(try Int64XDRJsonCodec.toXdrJson(-1), #""-1""#)

        // A JSON number is accepted on input for XDR-JSON v1 compatibility.
        let fromNumbers = try LiabilitiesXDR.fromXdrJson(#"{"buying":-1,"selling":5}"#)
        XCTAssertEqual(try fromNumbers.toXdrJson(), #"{"buying":"-1","selling":"5"}"#)
    }

    // MARK: - Optional fields and void union arms

    func testVoidArmsAndValuedArms() throws {
        XCTAssertEqual(try MemoXDR.none.toXdrJson(), #""none""#)
        XCTAssertEqual(try AssetXDR.native.toXdrJson(), #""native""#)
        XCTAssertEqual(try MemoXDR.text("tag\ttest").toXdrJson(), #"{"text":"tag\\ttest"}"#)
    }

    func testAnAbsentOptionalKeepsItsKey() throws {
        // source_account is an absent optional; inflation is a void arm and so a bare string.
        let operation = try OperationXDR.fromXdrJson(#"{"source_account":null,"body":"inflation"}"#)
        XCTAssertNil(operation.sourceAccount)

        // Dropping the key is an error rather than a shorthand for null.
        XCTAssertThrowsError(try OperationXDR.fromXdrJson(#"{"body":"inflation"}"#)) { error in
            XCTAssertEqual((error as? XdrJsonError)?.message,
                           "OperationXDR: missing key \"source_account\"")
        }

        // Writing a void arm as if it carried a value is rejected, and the message says so.
        XCTAssertThrowsError(
            try OperationXDR.fromXdrJson(#"{"source_account":null,"body":{"inflation":null}}"#)
        ) { error in
            XCTAssertEqual((error as? XdrJsonError)?.message,
                           "OperationBodyXDR.inflation: this arm carries no value, so it is "
                           + "written as a bare string")
        }
    }

    // MARK: - Byte equality and structural equality

    func testStructuralEqualityRatherThanByteEquality() throws {
        let canonical = #"{"min_time":"0","max_time":"1"}"#
        let foreign   = #"{ "max_time" : "1", "min_time" : "0" }"#

        XCTAssertNotEqual(canonical, foreign)

        let a = try TimeBoundsXDR.fromXdrJson(canonical)
        let b = try TimeBoundsXDR.fromXdrJson(foreign)
        XCTAssertEqual(try a.toXdrJson(), try b.toXdrJson())
    }

    // MARK: - The $schema property

    func testSchemaPropertyIsAcceptedAndStripped() throws {
        let withSchema = #"{"$schema":"https://example.com/xdr.json","min_time":"0","max_time":"1"}"#

        let bounds = try TimeBoundsXDR.fromXdrJson(withSchema)
        XCTAssertEqual(try bounds.toXdrJson(), #"{"min_time":"0","max_time":"1"}"#)

        // An object carrying nothing but $schema has no value to read.
        XCTAssertThrowsError(
            try TimeBoundsXDR.fromXdrJson(#"{"$schema":"https://example.com/xdr.json"}"#))
    }

    // MARK: - Divergences from the reference implementation

    func testInlineFixedOpaqueRendersAsHex() throws {
        let secret = Curve25519SecretXDR(key: WrappedData32(Data(repeating: 0x07, count: 32)))
        XCTAssertEqual(try secret.toXdrJson(),
                       #"{"key":"0707070707070707070707070707070707070707070707070707070707070707"}"#)
    }

    // MARK: - Limitations

    func testZeroLengthSignedPayloadIsUnrepresentable() throws {
        let payload = Ed25519SignedPayload(ed25519: WrappedData32(Data(repeating: 0x01, count: 32)),
                                           payload: Data())

        XCTAssertThrowsError(try SignerKeyXDR.signedPayload(payload).toXdrJson()) { error in
            XCTAssertEqual((error as? XdrJsonError)?.message,
                           "Ed25519SignedPayload: a signed payload of zero length has no strkey "
                           + "the ecosystem accepts")
        }

        // A one-byte payload is inside the accepted domain.
        let shortest = Ed25519SignedPayload(ed25519: WrappedData32(Data(repeating: 0x01, count: 32)),
                                            payload: Data([0x2a]))
        XCTAssertNoThrow(try SignerKeyXDR.signedPayload(shortest).toXdrJson())
    }

    // MARK: - Error handling

    func testUnknownKeyNamesTheDeclaredKeys() throws {
        do {
            let _ = try TimeBoundsXDR.fromXdrJson(#"{"min_time":"0","max_time":"1","foo":1}"#)
            XCTFail("an undeclared key must be rejected")
        } catch let error as XdrJsonError {
            XCTAssertEqual(error.message,
                           "TimeBoundsXDR: unknown key \"foo\"; declared keys are min_time, max_time")
        }
    }

    func testTheQuotedErrorMessages() throws {
        assertMessage("TimeBoundsXDR: missing key \"max_time\"") {
            _ = try TimeBoundsXDR.fromXdrJson(#"{"min_time":"0"}"#)
        }
        assertMessage("TimeBoundsXDR.min_time: expected string or number, got boolean") {
            _ = try TimeBoundsXDR.fromXdrJson(#"{"min_time":true,"max_time":"1"}"#)
        }
        assertMessage("TimeBoundsXDR.min_time: not a base-10 integer: 1e10") {
            _ = try TimeBoundsXDR.fromXdrJson(#"{"min_time":"1e10","max_time":"1"}"#)
        }
        assertMessage("AssetType: unknown value \"bogus\"") {
            _ = try AssetType.fromXdrJson(#""bogus""#)
        }
        assertMessage("MemoXDR: unknown union arm \"bogus\"") {
            _ = try MemoXDR.fromXdrJson(#"{"bogus":1}"#)
        }
    }

    // MARK: - Duplicate keys depend on the entry point

    func testDuplicateKeyInTextIsMalformedJson() throws {
        do {
            let _ = try TimeBoundsXDR.fromXdrJson(
                #"{"min_time":"0","min_time":"1","max_time":"1"}"#)
            XCTFail("a duplicate key must be rejected")
        } catch let error as XdrJsonError {
            guard case .malformedJson = error else {
                return XCTFail("expected malformedJson, got \(error)")
            }
            XCTAssertEqual(error.message, "malformed JSON: duplicate object key \"min_time\"")
        }
    }

    func testDuplicateKeyInAHandBuiltTreeNamesTheType() throws {
        let tree = XdrJsonValue.object([
            XdrJsonMember(key: "min_time", value: .string("0")),
            XdrJsonMember(key: "min_time", value: .string("1")),
            XdrJsonMember(key: "max_time", value: .string("1"))
        ])

        do {
            let _ = try TimeBoundsXDR.fromXdrJsonTree(tree)
            XCTFail("a duplicate key must be rejected")
        } catch let error as XdrJsonError {
            guard case .duplicateKey = error else {
                return XCTFail("expected duplicateKey, got \(error)")
            }
            XCTAssertEqual(error.message, "TimeBoundsXDR: duplicate key \"min_time\"")
        }
    }

    // MARK: - Helpers

    private func assertMessage(_ expected: String,
                               file: StaticString = #filePath,
                               line: UInt = #line,
                               _ body: () throws -> Void) {
        do {
            try body()
            XCTFail("expected \(expected)", file: file, line: line)
        } catch let error as XdrJsonError {
            XCTAssertEqual(error.message, expected, file: file, line: line)
        } catch {
            XCTFail("expected XdrJsonError, got \(error)", file: file, line: line)
        }
    }
}
