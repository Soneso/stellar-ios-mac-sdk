//
//  Sep51NameDerivationUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// The wire names SEP-0051 derives from the XDR identifiers, where the derivation is not
/// obvious from the identifier alone.
///
/// SEP-0051 §Enum and §Discriminated Union say the JSON name is the identifier in snake_case
/// with the enumeration's shared prefix removed. Each rule below is a place where a plausible
/// reading of that sentence gives a different answer from the correct one, so each is pinned
/// against its literal wire string rather than against a round trip. A round trip cannot see
/// a wrong name: it agrees with itself.
///
/// The names derive from the XDR identifier, never from the Swift spelling. Several of the
/// cases below exist precisely because the two differ: `IPAddrType` declares `IPv4` and this
/// SDK's generated case is `pv4`, and `ClaimantV0` declares `destination` where the generated
/// property is `accountID`.
final class Sep51NameDerivationUnitTests: XCTestCase {

    // MARK: - A shared prefix with no underscore is not removed

    /// `OperationResultCode` has the common prefix `op`, which carries no underscore, so
    /// nothing is stripped and the arm keeps its `op_` lead.
    func testOperationResultKeepsItsOpPrefix() throws {
        let inner = OperationResultXDR.tr(.createAccountResult(.success))
        XCTAssertEqual(try inner.toXdrJson(), "{\"op_inner\":{\"create_account\":\"success\"}}")
        XCTAssertEqual(try OperationResultXDR.badAuth.toXdrJson(), "\"op_bad_auth\"")

        let read = try OperationResultXDR.fromXdrJson("{\"op_inner\":{\"create_account\":\"success\"}}")
        XCTAssertEqual(try Self.base64(read), try Self.base64(inner))
    }

    /// `TransactionResultCode` has the common prefix `tx` for the same reason.
    func testTransactionResultKeepsItsTxPrefix() throws {
        XCTAssertEqual(try TransactionResultCode.success.toXdrJson(), "\"tx_success\"")
        XCTAssertEqual(try TransactionResultCode.badSeq.toXdrJson(), "\"tx_bad_seq\"")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_success\""), .success)

        XCTAssertEqual(try TransactionResultBodyXDR.success([]).toXdrJson(), "{\"tx_success\":[]}")
    }

    // MARK: - A single-member enumeration is never stripped

    /// The shared prefix of an enumeration with one member is empty, so the whole identifier
    /// survives. Stripping it would leave nothing at all.
    func testSingleMemberEnumerationsKeepTheirWholeIdentifier() throws {
        XCTAssertEqual(try PublicKeyTypeXDR.publicKeyTypeEd25519.toXdrJson(),
                       "\"public_key_type_ed25519\"")
        XCTAssertEqual(try PublicKeyTypeXDR.fromXdrJson("\"public_key_type_ed25519\""),
                       .publicKeyTypeEd25519)

        XCTAssertEqual(try ClaimantType.claimantTypeV0.toXdrJson(), "\"claimant_type_v0\"")
        XCTAssertEqual(try ClaimantType.fromXdrJson("\"claimant_type_v0\""), .claimantTypeV0)
    }

    func testSingleArmUnionUsesItsMembersUnstrippedName() throws {
        let claimant = ClaimantXDR.claimantTypeV0(
            ClaimantV0XDR(accountID: try PublicKey(Array(repeating: 0, count: 32)),
                          predicate: .claimPredicateUnconditional))
        let expected = "{\"claimant_type_v0\":{"
            + "\"destination\":\"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF\","
            + "\"predicate\":\"unconditional\"}}"

        XCTAssertEqual(try claimant.toXdrJson(), expected)
        XCTAssertEqual(try Self.base64(try ClaimantXDR.fromXdrJson(expected)),
                       try Self.base64(claimant))
    }

    // MARK: - Word splitting inside an identifier

    /// `IPv4` splits into `I` and `Pv4`, which is what yields `i_pv4`. The generated Swift
    /// case is `pv4`, so a name taken from the language rather than from the XDR identifier
    /// would emit `pv4` and round-trip against itself perfectly while being wrong.
    func testAcronymFollowedByADigitSplitsBeforeTheDigit() throws {
        XCTAssertEqual(try IPAddrTypeXDR.pv4.toXdrJson(), "\"i_pv4\"")
        XCTAssertEqual(try IPAddrTypeXDR.pv6.toXdrJson(), "\"i_pv6\"")
        XCTAssertEqual(try IPAddrTypeXDR.fromXdrJson("\"i_pv4\""), .pv4)
        XCTAssertEqual(try IPAddrTypeXDR.fromXdrJson("\"i_pv6\""), .pv6)
    }

    func testCamelCasedIdentifierSplitsOnEveryWord() throws {
        XCTAssertEqual(try ContractCostType.wasmInsnExec.toXdrJson(), "\"wasm_insn_exec\"")
        XCTAssertEqual(try ContractCostType.fromXdrJson("\"wasm_insn_exec\""), .wasmInsnExec)
    }

    /// A struct field named `signerSponsoringIDs` splits before the final `s` of the acronym
    /// run, so the key is `signer_sponsoring_i_ds`.
    func testStructFieldAcronymRunSplitsBeforeItsLastLetter() throws {
        let value = AccountEntryExtensionV2(numSponsored: 1, numSponsoring: 2,
                                            signerSponsoringIDs: [], reserved: .void)
        XCTAssertEqual(try value.toXdrJson(),
                       "{\"num_sponsored\":1,\"num_sponsoring\":2,"
                       + "\"signer_sponsoring_i_ds\":[],\"ext\":\"v0\"}")
    }

    // MARK: - A remainder that begins with a digit

    /// Stripping `BINARY_FUSE_FILTER_` from `BINARY_FUSE_FILTER_8_BIT` leaves `8_BIT`, which
    /// cannot start an identifier, so the prefix's own first character is put back. It is that
    /// character and not a fixed letter, which is why all three members lead with `b`.
    func testDigitLeadingRemainderRegainsTheFirstCharacterOfThePrefix() throws {
        XCTAssertEqual(try BinaryFuseFilterTypeXDR.eightBit.toXdrJson(), "\"b8_bit\"")
        XCTAssertEqual(try BinaryFuseFilterTypeXDR.sixteenBit.toXdrJson(), "\"b16_bit\"")
        XCTAssertEqual(try BinaryFuseFilterTypeXDR.thirtyTwoBit.toXdrJson(), "\"b32_bit\"")

        XCTAssertEqual(try BinaryFuseFilterTypeXDR.fromXdrJson("\"b8_bit\""), .eightBit)
        XCTAssertEqual(try BinaryFuseFilterTypeXDR.fromXdrJson("\"b16_bit\""), .sixteenBit)
        XCTAssertEqual(try BinaryFuseFilterTypeXDR.fromXdrJson("\"b32_bit\""), .thirtyTwoBit)
    }

    // MARK: - Result codes whose stripped remainder is short

    func testClawbackResultCodeStripsOnlyTheSharedPrefix() throws {
        XCTAssertEqual(try ClawbackResultCode.notClawbackEnabled.toXdrJson(),
                       "\"not_clawback_enabled\"")
        XCTAssertEqual(try ClawbackResultCode.fromXdrJson("\"not_clawback_enabled\""),
                       .notClawbackEnabled)
        XCTAssertEqual(try ClawbackResultXDR.notClawbackEnabled.toXdrJson(),
                       "\"not_clawback_enabled\"")
    }

    func testCreateAccountResultCodeStripsOnlyTheSharedPrefix() throws {
        XCTAssertEqual(try CreateAccountResultCode.alreadyExist.toXdrJson(), "\"already_exist\"")
        XCTAssertEqual(try CreateAccountResultCode.fromXdrJson("\"already_exist\""), .alreadyExist)
        XCTAssertEqual(try CreateAccountResultXDR.alreadyExist.toXdrJson(), "\"already_exist\"")
    }

    // MARK: - A union over a subset of its discriminant

    /// `FeeBumpTransactionInnerTx` switches over exactly one `EnvelopeType` member. The shared
    /// prefix is a property of the enumeration, not of the union, so it is computed from
    /// `EnvelopeType`'s full member list and the arm key is `tx`. Deriving it from the union's
    /// own single case would leave the prefix empty and give `envelope_type_tx`.
    func testSubsetUnionTakesItsArmKeyFromTheWholeDiscriminantEnumeration() throws {
        let envelope = try XDRDecoder.decode(TransactionEnvelopeXDR.self,
                                             data: try Self.data(Self.feeBumpBase64))

        XCTAssertEqual(try envelope.toXdrJson(), Self.feeBumpJson)
        XCTAssertTrue(Self.feeBumpJson.contains("\"inner_tx\":{\"tx\":"), Self.feeBumpJson)
        XCTAssertFalse(Self.feeBumpJson.contains("envelope_type_tx"), Self.feeBumpJson)

        let read = try TransactionEnvelopeXDR.fromXdrJson(Self.feeBumpJson)
        XCTAssertEqual(try Self.base64(read), Self.feeBumpBase64)
    }

    func testSubsetUnionRejectsTheUnstrippedArmName() {
        let document = "{\"envelope_type_tx\":{\"tx\":{\"source_account\":\"G\"},\"signatures\":[]}}"

        XCTAssertThrowsError(try FeeBumpTransactionXDRInnerTxXDR.fromXdrJson(document)) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "FeeBumpTransactionXDRInnerTxXDR")
            XCTAssertEqual(key, "envelope_type_tx")
        }
    }

    // MARK: - The reserved field name

    /// SEP-0051 §Struct keeps a field named `type` spelled `type`. Earlier reference releases
    /// wrote the escaped spelling `type_`, so both are accepted on input and only `type` is
    /// written.
    func testFieldNamedTypeIsEmittedUnescapedAndReadUnderBothSpellings() throws {
        let value = DontHaveXDR(type: .errorMsg, reqHash: Uint256XDR(Data(Self.keyBytes)))
        let expected = "{\"type\":\"error_msg\",\"req_hash\":\"\(Self.hashHex)\"}"
        let escapedSpelling = "{\"type_\":\"error_msg\",\"req_hash\":\"\(Self.hashHex)\"}"

        XCTAssertEqual(try value.toXdrJson(), expected)
        XCTAssertEqual(try Self.base64(try DontHaveXDR.fromXdrJson(expected)), try Self.base64(value))
        XCTAssertEqual(try Self.base64(try DontHaveXDR.fromXdrJson(escapedSpelling)),
                       try Self.base64(value))
        XCTAssertEqual(try DontHaveXDR.fromXdrJson(escapedSpelling).toXdrJson(), expected)
    }

    // MARK: - Integer-cased unions

    /// SEP-0051 §Discriminated Union says an integer-cased union takes the name `v` followed
    /// by the case integer. The discriminant's declared name never reaches the wire, and an
    /// extension point holding a void arm is the string `"v0"` rather than the number `0`.
    func testIntegerCasedUnionsUseTheVNumberForm() throws {
        XCTAssertEqual(try ExtensionPoint.void.toXdrJson(), "\"v0\"")
        XCTAssertEqual(try SorobanTransactionMetaExt.void.toXdrJson(), "\"v0\"")
        XCTAssertEqual(try AccountEntryExtV2XDR.void.toXdrJson(), "\"v0\"")

        XCTAssertEqual(try Self.base64(try ExtensionPoint.fromXdrJson("\"v0\"")),
                       try Self.base64(ExtensionPoint.void))
    }

    func testIntegerCasedUnionRejectsTheNumericSpelling() {
        XCTAssertThrowsError(try ExtensionPoint.fromXdrJson("0")) { error in
            guard case XdrJsonError.unexpectedType(let type, _, _, let got) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "ExtensionPoint")
            XCTAssertEqual(got, "number")
        }
    }

    // MARK: - Fixtures

    private static let keyBytes: [UInt8] = (0..<32).map { UInt8($0) }
    private static let hashHex = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"

    private static let feeBumpBase64 =
        "AAAABQAAAQAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMgAAAACAAAA"
        + "AOaZJmTBjfXrdMyi4HZNjwyWOpfDYjFVhMbK8OtHpi0AAAAAZAAAGm4AAAABAAAAAAAAAAAAAAAAAAAAAAAA"
        + "AAAAAAAAAAAAAA=="

    private static let feeBumpJson = """
    {"tx_fee_bump":{"tx":{"fee_source":\
    "MAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFNZG","fee":"200",\
    "inner_tx":{"tx":{"tx":{"source_account":\
    "GDTJSJTEYGG7L23UZSROA5SNR4GJMOUXYNRDCVMEY3FPB22HUYWQBZIA","fee":100,\
    "seq_num":"29059748724737","cond":"none","memo":"none","operations":[],"ext":"v0"},\
    "signatures":[]}},"ext":"v0"},"signatures":[]}}
    """

    // MARK: - Helpers

    private static func data(_ base64: String) throws -> Data {
        try XCTUnwrap(Data(base64Encoded: base64), "not base64: \(base64)")
    }

    private static func base64(_ value: XDREncodable) throws -> String {
        Data(try XDREncoder.encode(value)).base64EncodedString()
    }
}
