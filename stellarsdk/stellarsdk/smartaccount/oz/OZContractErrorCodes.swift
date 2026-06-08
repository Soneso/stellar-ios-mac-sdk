//
//  OZContractErrorCodes.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// Reference constants for a subset of the OpenZeppelin smart-account contract's
/// on-chain error codes.
///
/// When the contract rejects a call, the code appears inside the message of a
/// `SmartAccountTransactionException` (for example `Error(Contract, #3016)`). The SDK
/// surfaces the raw error but does not parse or map contract error codes itself;
/// callers can extract the code from the message and compare it against these constants.
///
/// Error code range: `3xxx` (credential errors, aligned with the contract's `Error` enum).
public enum OZContractErrorCodes {

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
}
