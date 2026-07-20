//
//  OZContractErrorCodesTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Decoding of OZ smart-account, WebAuthn, and policy contract error codes into their
/// defining contract and variant name.
final class OZContractErrorCodesTests: XCTestCase {

    func testDecode_smartAccountCodes() {
        XCTAssertEqual(
            OZContractError(code: 3000, contract: "SmartAccountError", name: "ContextRuleNotFound"),
            OZContractErrorCodes.decode(3000)
        )
        XCTAssertEqual(
            OZContractError(code: 3015, contract: "SmartAccountError", name: "NameTooLong"),
            OZContractErrorCodes.decode(3015)
        )
        XCTAssertEqual(
            OZContractError(code: 3016, contract: "SmartAccountError", name: "UnauthorizedSigner"),
            OZContractErrorCodes.decode(3016)
        )
    }

    func testDecode_webAuthnCode() {
        XCTAssertEqual(
            OZContractError(code: 3114, contract: "WebAuthnError", name: "ChallengeInvalid"),
            OZContractErrorCodes.decode(3114)
        )
        XCTAssertEqual(
            OZContractError(code: 3110, contract: "WebAuthnError", name: "SignaturePayloadInvalid"),
            OZContractErrorCodes.decode(3110)
        )
    }

    func testDecode_policyCode() {
        XCTAssertEqual(
            OZContractError(code: 3221, contract: "SpendingLimitError", name: "SpendingLimitExceeded"),
            OZContractErrorCodes.decode(3221)
        )
        XCTAssertEqual(
            OZContractError(code: 3227, contract: "SpendingLimitError", name: "OnlyCallContractAllowed"),
            OZContractErrorCodes.decode(3227)
        )
    }

    func testDecode_repeatedNames_disambiguatedByContract() {
        // "NotAllowed" appears in all three policy enums at distinct codes.
        XCTAssertEqual("SimpleThresholdError", OZContractErrorCodes.decode(3202)?.contract)
        XCTAssertEqual("WeightedThresholdError", OZContractErrorCodes.decode(3213)?.contract)
        XCTAssertEqual("SpendingLimitError", OZContractErrorCodes.decode(3223)?.contract)
        XCTAssertEqual("NotAllowed", OZContractErrorCodes.decode(3202)?.name)
        XCTAssertEqual("NotAllowed", OZContractErrorCodes.decode(3213)?.name)
        XCTAssertEqual("NotAllowed", OZContractErrorCodes.decode(3223)?.name)

        // "MathOverflow" exists in both the smart account and weighted-threshold enums.
        XCTAssertEqual(
            OZContractError(code: 3012, contract: "SmartAccountError", name: "MathOverflow"),
            OZContractErrorCodes.decode(3012)
        )
        XCTAssertEqual(
            OZContractError(code: 3212, contract: "WeightedThresholdError", name: "MathOverflow"),
            OZContractErrorCodes.decode(3212)
        )
    }

    func testDecode_unusedAndGapCodes_returnNil() {
        // 3001 is unused in SmartAccountError; the policy enums have gaps.
        XCTAssertNil(OZContractErrorCodes.decode(3001))
        XCTAssertNil(OZContractErrorCodes.decode(3204))
        XCTAssertNil(OZContractErrorCodes.decode(3215))
        XCTAssertNil(OZContractErrorCodes.decode(3120))
    }

    func testDecode_outOfRangeCodes_returnNil() {
        XCTAssertNil(OZContractErrorCodes.decode(0))
        XCTAssertNil(OZContractErrorCodes.decode(2999))
        XCTAssertNil(OZContractErrorCodes.decode(9999))
        XCTAssertNil(OZContractErrorCodes.decode(-1))
    }

    func testConstants_matchDecodeTable() {
        XCTAssertEqual(3000, OZContractErrorCodes.contextRuleNotFound)
        XCTAssertEqual(3015, OZContractErrorCodes.nameTooLong)
        XCTAssertEqual(3016, OZContractErrorCodes.unauthorizedSigner)
        XCTAssertEqual("NameTooLong", OZContractErrorCodes.decode(OZContractErrorCodes.nameTooLong)?.name)
    }

    func testConstants_preexistingValuesUnchanged() {
        XCTAssertEqual(3012, OZContractErrorCodes.mathOverflow)
        XCTAssertEqual(3013, OZContractErrorCodes.keyDataTooLarge)
        XCTAssertEqual(3014, OZContractErrorCodes.contextRuleIdsLengthMismatch)
        XCTAssertEqual(3015, OZContractErrorCodes.nameTooLong)
        XCTAssertEqual(3016, OZContractErrorCodes.unauthorizedSigner)
    }

    func testDecode_fullTableMatchesContractEnums() {
        // Independent transcription of the contract enums; a transposed name or wrong
        // contract in the production table fails here.
        let expected: [Int: (contract: String, name: String)] = [
            3000: ("SmartAccountError", "ContextRuleNotFound"),
            3002: ("SmartAccountError", "UnvalidatedContext"),
            3003: ("SmartAccountError", "ExternalVerificationFailed"),
            3004: ("SmartAccountError", "NoSignersAndPolicies"),
            3005: ("SmartAccountError", "PastValidUntil"),
            3006: ("SmartAccountError", "SignerNotFound"),
            3007: ("SmartAccountError", "DuplicateSigner"),
            3008: ("SmartAccountError", "PolicyNotFound"),
            3009: ("SmartAccountError", "DuplicatePolicy"),
            3010: ("SmartAccountError", "TooManySigners"),
            3011: ("SmartAccountError", "TooManyPolicies"),
            3012: ("SmartAccountError", "MathOverflow"),
            3013: ("SmartAccountError", "KeyDataTooLarge"),
            3014: ("SmartAccountError", "ContextRuleIdsLengthMismatch"),
            3015: ("SmartAccountError", "NameTooLong"),
            3016: ("SmartAccountError", "UnauthorizedSigner"),
            3110: ("WebAuthnError", "SignaturePayloadInvalid"),
            3111: ("WebAuthnError", "ClientDataTooLong"),
            3112: ("WebAuthnError", "JsonParseError"),
            3113: ("WebAuthnError", "TypeFieldInvalid"),
            3114: ("WebAuthnError", "ChallengeInvalid"),
            3115: ("WebAuthnError", "AuthDataFormatInvalid"),
            3116: ("WebAuthnError", "PresentBitNotSet"),
            3117: ("WebAuthnError", "VerifiedBitNotSet"),
            3118: ("WebAuthnError", "BackupEligibilityAndStateNotSet"),
            3119: ("WebAuthnError", "KeyDataInvalid"),
            3200: ("SimpleThresholdError", "SmartAccountNotInstalled"),
            3201: ("SimpleThresholdError", "InvalidThreshold"),
            3202: ("SimpleThresholdError", "NotAllowed"),
            3203: ("SimpleThresholdError", "AlreadyInstalled"),
            3210: ("WeightedThresholdError", "SmartAccountNotInstalled"),
            3211: ("WeightedThresholdError", "InvalidThreshold"),
            3212: ("WeightedThresholdError", "MathOverflow"),
            3213: ("WeightedThresholdError", "NotAllowed"),
            3214: ("WeightedThresholdError", "AlreadyInstalled"),
            3220: ("SpendingLimitError", "SmartAccountNotInstalled"),
            3221: ("SpendingLimitError", "SpendingLimitExceeded"),
            3222: ("SpendingLimitError", "InvalidLimitOrPeriod"),
            3223: ("SpendingLimitError", "NotAllowed"),
            3224: ("SpendingLimitError", "HistoryCapacityExceeded"),
            3225: ("SpendingLimitError", "AlreadyInstalled"),
            3226: ("SpendingLimitError", "LessThanZero"),
            3227: ("SpendingLimitError", "OnlyCallContractAllowed"),
        ]
        XCTAssertEqual(43, expected.count)
        for (code, contractAndName) in expected {
            XCTAssertEqual(
                OZContractError(code: code, contract: contractAndName.contract, name: contractAndName.name),
                OZContractErrorCodes.decode(code)
            )
        }
    }

    // MARK: - decodeFromMessage

    func testDecodeFromMessage_simulationErrorString() {
        let message = "Transaction simulation failed: Simulation error: HostError: Error(Context, InvalidAction) "
            + "Event log: [Diagnostic Event] topics:[error, Error(Context, InvalidAction)], "
            + "data:[\"constructor invocation has failed with error\", Error(Contract, #3201)]"
        XCTAssertEqual(
            OZContractError(code: 3201, contract: "SimpleThresholdError", name: "InvalidThreshold"),
            OZContractErrorCodes.decodeFromMessage(message)
        )
    }

    func testDecodeFromMessage_whitespaceVariants() {
        XCTAssertEqual(3227, OZContractErrorCodes.decodeFromMessage("Error(Contract, #3227)")?.code)
        XCTAssertEqual(3227, OZContractErrorCodes.decodeFromMessage("Error( Contract , #3227 )")?.code)
    }

    func testDecodeFromMessage_skipsUnknownCodeAndReturnsFirstKnown() {
        // 3001 is unused in the contract enums; the scan continues to the next marker.
        let message = "Error(Contract, #3001) then Error(Contract, #3114)"
        XCTAssertEqual(
            OZContractError(code: 3114, contract: "WebAuthnError", name: "ChallengeInvalid"),
            OZContractErrorCodes.decodeFromMessage(message)
        )
    }

    func testDecodeFromMessage_noMatchReturnsNil() {
        XCTAssertNil(OZContractErrorCodes.decodeFromMessage(nil))
        XCTAssertNil(OZContractErrorCodes.decodeFromMessage("no contract error here"))
        XCTAssertNil(OZContractErrorCodes.decodeFromMessage("Error(Contract, #3001)"))
        XCTAssertNil(OZContractErrorCodes.decodeFromMessage("Error(WasmVm, InternalError)"))
    }
}
