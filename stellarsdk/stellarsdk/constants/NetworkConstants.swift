//
//  NetworkConstants.swift
//  stellarsdk
//
//  Created on 30.10.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Network and HTTP-related constants used throughout the SDK.
/// These values define thresholds for HTTP response handling and network operations.
public struct NetworkConstants: Sendable {

    // MARK: - HTTP Status Codes

    /// Maximum HTTP status code considered successful (299)
    /// Status codes 200-299 indicate successful HTTP responses
    /// Status codes >= 300 indicate client or server errors
    /// Reference: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
    public static let HTTP_SUCCESS_STATUS_MAX = 299

    /// Minimum HTTP status code considered an error (300)
    /// Status codes >= 300 indicate redirects, client errors, or server errors
    /// Reference: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
    public static let HTTP_ERROR_STATUS_MIN = 300

    // MARK: - Transaction Timeouts

    /// Default transaction timeout in seconds (300 seconds = 5 minutes)
    /// Reference: [Stellar developer docs](https://developers.stellar.org)
    public static let DEFAULT_TIMEOUT_SECONDS:UInt64 = 300

    /// Transaction time buffer in seconds (10 seconds)
    ///
    /// Unused by the SDK: Soroban transactions set no lower time bound
    /// (minTime = 0). A lower bound derived from the client clock is seen as
    /// lying in the future by any submission node whose clock or ledger state
    /// lags the client, which rejects the transaction with tx_too_early.
    @available(*, deprecated, message: "Unused by the SDK; Soroban transactions set no lower time bound (minTime = 0).")
    public static let TRANSACTION_TIME_BUFFER_SECONDS = 10
}
