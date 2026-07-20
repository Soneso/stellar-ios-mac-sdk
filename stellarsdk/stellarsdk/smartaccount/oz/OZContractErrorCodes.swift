//
//  OZContractErrorCodes.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// A decoded OpenZeppelin smart-account contract error: its numeric `code`, the contract
/// error enum it belongs to (`contract`), and the `name` of the variant, exactly as
/// declared by the deployed contracts. Variant names repeat across the policy enums (for
/// example `NotAllowed`), so `contract` is required to disambiguate; `code` is globally
/// unique.
public struct OZContractError: Equatable, Hashable, Sendable {

    /// The numeric contract error code (for example `3016`).
    public let code: Int

    /// The contract error enum the code belongs to (for example `SmartAccountError`).
    public let contract: String

    /// The variant name inside `contract` (for example `UnauthorizedSigner`).
    public let name: String

    /// Initializes a decoded contract error from its `code`, defining `contract` enum,
    /// and variant `name`.
    public init(code: Int, contract: String, name: String) {
        self.code = code
        self.contract = contract
        self.name = name
    }
}

/// Contract-level error codes from the OpenZeppelin smart account, WebAuthn verifier, and
/// policy contracts.
///
/// When a contract rejects a call, the code appears inside the message of a
/// `SmartAccountTransactionException` (for example `Error(Contract, #3016)`). The SDK
/// surfaces the raw error but does not parse or map contract error codes itself; callers
/// can extract the code from the message and compare it against these constants, or
/// resolve it with the consumer-side ``decode(_:)`` and ``decodeFromMessage(_:)`` helpers.
///
/// The named constants below cover the smart account contract's own error enum — the
/// codes a caller is most likely to branch on. ``decode(_:)`` resolves any known code
/// (smart account, WebAuthn, or a policy contract) into its contract and variant name.
public enum OZContractErrorCodes {

    // Smart account contract (SmartAccountError, codes 3000-3016; 3001 is unused).

    /// The referenced context rule does not exist on the account.
    public static let contextRuleNotFound: Int = 3000

    /// The invocation context could not be validated against the account's context rules.
    public static let unvalidatedContext: Int = 3002

    /// An external signer's verifier contract rejected the signature.
    public static let externalVerificationFailed: Int = 3003

    /// A context rule must have at least one signer or one policy.
    public static let noSignersAndPolicies: Int = 3004

    /// The context rule's `valid_until` ledger has already passed.
    public static let pastValidUntil: Int = 3005

    /// The referenced signer is not present on the context rule.
    public static let signerNotFound: Int = 3006

    /// The signer is already present on the context rule.
    public static let duplicateSigner: Int = 3007

    /// The referenced policy is not installed on the context rule.
    public static let policyNotFound: Int = 3008

    /// The policy is already installed on the context rule.
    public static let duplicatePolicy: Int = 3009

    /// The context rule exceeds the maximum number of signers.
    public static let tooManySigners: Int = 3010

    /// The context rule exceeds the maximum number of policies.
    public static let tooManyPolicies: Int = 3011

    /// Integer arithmetic overflow occurred in the contract.
    public static let mathOverflow: Int = 3012

    /// The `key_data` field on a signer exceeds the maximum allowed size.
    public static let keyDataTooLarge: Int = 3013

    /// The number of context rule IDs in the auth payload does not match the expected count.
    public static let contextRuleIdsLengthMismatch: Int = 3014

    /// A name field (e.g. context rule name) exceeds the maximum allowed length.
    public static let nameTooLong: Int = 3015

    /// The signer is not authorized to sign the given context rule.
    public static let unauthorizedSigner: Int = 3016

    /// Decodes a raw contract error `code` into the OZ contract and variant name that
    /// defined it, or `nil` if `code` is not a known OZ smart-account contract error.
    ///
    /// - Parameter code: The numeric contract error code to decode.
    /// - Returns: The decoded ``OZContractError``, or `nil` for unknown codes.
    public static func decode(_ code: Int) -> OZContractError? {
        return codeTable[code]
    }

    /// Extracts and decodes the first known contract error code from an error `message`.
    ///
    /// Soroban RPC surfaces contract failures as `Error(Contract, #NNNN)` inside
    /// simulation and submission error strings (typically the message of a thrown
    /// `SmartAccountTransactionException`). This scans the message for such markers and
    /// returns the first one whose code is a known OZ smart-account contract error, or
    /// `nil` when the message is `nil`, carries no marker, or carries only unknown codes.
    ///
    /// - Parameter message: The error message to scan.
    /// - Returns: The decoded ``OZContractError``, or `nil` when no known code is found.
    public static func decodeFromMessage(_ message: String?) -> OZContractError? {
        guard let message = message, let regex = contractErrorRegex else {
            return nil
        }
        let range = NSRange(message.startIndex..<message.endIndex, in: message)
        for match in regex.matches(in: message, options: [], range: range) {
            guard let codeRange = Range(match.range(at: 1), in: message),
                  let code = Int(message[codeRange]),
                  let decoded = decode(code) else {
                continue
            }
            return decoded
        }
        return nil
    }

    /// Matches `Error(Contract, #NNNN)` markers with whitespace tolerance. The pattern
    /// is a compile-time constant, so initialization cannot fail.
    private static let contractErrorRegex: NSRegularExpression? =
        try? NSRegularExpression(pattern: #"Error\s*\(\s*Contract\s*,\s*#(\d+)\s*\)"#, options: [])

    /// Every known contract error, keyed by its globally unique code.
    private static let codeTable: [Int: OZContractError] = {
        let allErrors: [OZContractError] = [
            // SmartAccountError (3000-3016; 3001 unused)
            OZContractError(code: 3000, contract: "SmartAccountError", name: "ContextRuleNotFound"),
            OZContractError(code: 3002, contract: "SmartAccountError", name: "UnvalidatedContext"),
            OZContractError(code: 3003, contract: "SmartAccountError", name: "ExternalVerificationFailed"),
            OZContractError(code: 3004, contract: "SmartAccountError", name: "NoSignersAndPolicies"),
            OZContractError(code: 3005, contract: "SmartAccountError", name: "PastValidUntil"),
            OZContractError(code: 3006, contract: "SmartAccountError", name: "SignerNotFound"),
            OZContractError(code: 3007, contract: "SmartAccountError", name: "DuplicateSigner"),
            OZContractError(code: 3008, contract: "SmartAccountError", name: "PolicyNotFound"),
            OZContractError(code: 3009, contract: "SmartAccountError", name: "DuplicatePolicy"),
            OZContractError(code: 3010, contract: "SmartAccountError", name: "TooManySigners"),
            OZContractError(code: 3011, contract: "SmartAccountError", name: "TooManyPolicies"),
            OZContractError(code: 3012, contract: "SmartAccountError", name: "MathOverflow"),
            OZContractError(code: 3013, contract: "SmartAccountError", name: "KeyDataTooLarge"),
            OZContractError(code: 3014, contract: "SmartAccountError", name: "ContextRuleIdsLengthMismatch"),
            OZContractError(code: 3015, contract: "SmartAccountError", name: "NameTooLong"),
            OZContractError(code: 3016, contract: "SmartAccountError", name: "UnauthorizedSigner"),
            // WebAuthnError (3110-3119)
            OZContractError(code: 3110, contract: "WebAuthnError", name: "SignaturePayloadInvalid"),
            OZContractError(code: 3111, contract: "WebAuthnError", name: "ClientDataTooLong"),
            OZContractError(code: 3112, contract: "WebAuthnError", name: "JsonParseError"),
            OZContractError(code: 3113, contract: "WebAuthnError", name: "TypeFieldInvalid"),
            OZContractError(code: 3114, contract: "WebAuthnError", name: "ChallengeInvalid"),
            OZContractError(code: 3115, contract: "WebAuthnError", name: "AuthDataFormatInvalid"),
            OZContractError(code: 3116, contract: "WebAuthnError", name: "PresentBitNotSet"),
            OZContractError(code: 3117, contract: "WebAuthnError", name: "VerifiedBitNotSet"),
            OZContractError(code: 3118, contract: "WebAuthnError", name: "BackupEligibilityAndStateNotSet"),
            OZContractError(code: 3119, contract: "WebAuthnError", name: "KeyDataInvalid"),
            // SimpleThresholdError (3200-3203)
            OZContractError(code: 3200, contract: "SimpleThresholdError", name: "SmartAccountNotInstalled"),
            OZContractError(code: 3201, contract: "SimpleThresholdError", name: "InvalidThreshold"),
            OZContractError(code: 3202, contract: "SimpleThresholdError", name: "NotAllowed"),
            OZContractError(code: 3203, contract: "SimpleThresholdError", name: "AlreadyInstalled"),
            // WeightedThresholdError (3210-3214)
            OZContractError(code: 3210, contract: "WeightedThresholdError", name: "SmartAccountNotInstalled"),
            OZContractError(code: 3211, contract: "WeightedThresholdError", name: "InvalidThreshold"),
            OZContractError(code: 3212, contract: "WeightedThresholdError", name: "MathOverflow"),
            OZContractError(code: 3213, contract: "WeightedThresholdError", name: "NotAllowed"),
            OZContractError(code: 3214, contract: "WeightedThresholdError", name: "AlreadyInstalled"),
            // SpendingLimitError (3220-3227)
            OZContractError(code: 3220, contract: "SpendingLimitError", name: "SmartAccountNotInstalled"),
            OZContractError(code: 3221, contract: "SpendingLimitError", name: "SpendingLimitExceeded"),
            OZContractError(code: 3222, contract: "SpendingLimitError", name: "InvalidLimitOrPeriod"),
            OZContractError(code: 3223, contract: "SpendingLimitError", name: "NotAllowed"),
            OZContractError(code: 3224, contract: "SpendingLimitError", name: "HistoryCapacityExceeded"),
            OZContractError(code: 3225, contract: "SpendingLimitError", name: "AlreadyInstalled"),
            OZContractError(code: 3226, contract: "SpendingLimitError", name: "LessThanZero"),
            OZContractError(code: 3227, contract: "SpendingLimitError", name: "OnlyCallContractAllowed"),
        ]
        return Dictionary(uniqueKeysWithValues: allErrors.map { ($0.code, $0) })
    }()
}
