//
//  OZConstants.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// Configuration defaults and contract limits for OpenZeppelin smart account operations.
public enum OZConstants {

    /// Default session expiry in milliseconds (7 days).
    public static let defaultSessionExpiryMs: Int64 = 604_800_000

    /// Default HTTP timeout for indexer requests in milliseconds (10 seconds).
    public static let defaultIndexerTimeoutMs: Int64 = 10_000

    /// Default HTTP timeout for relayer requests in milliseconds (6 minutes).
    public static let defaultRelayerTimeoutMs: Int64 = 360_000

    /// XLM amount retained in the temporary account as minimum balance reserve when
    /// transferring Friendbot funds to a smart account wallet.
    public static let friendbotReserveXlm: Int = 5

    /// Interval in milliseconds between Soroban RPC polls while waiting for a
    /// freshly created ledger entry to become visible to the RPC. Shared by the
    /// funding-account visibility wait in
    /// ``OZTransactionOperations/waitForAccountVisibleToRpc(accountId:pollIntervalMs:timeoutSeconds:)``
    /// and the deployed-contract visibility wait in
    /// ``OZTransactionOperations/waitForContractVisibleToRpc(contractId:pollIntervalMs:timeoutSeconds:)``.
    public static let rpcVisibilityPollIntervalMs: Int = 1500

    /// Overall timeout in seconds for a freshly created ledger entry to become
    /// visible to the Soroban RPC. A funded account or a deployed contract
    /// confirms on Horizon within milliseconds, but the Soroban RPC may lag by
    /// one or more ledger closes; polling absorbs that variable propagation
    /// delay rather than assuming a single fixed wait. Shared by
    /// ``OZTransactionOperations/waitForAccountVisibleToRpc(accountId:pollIntervalMs:timeoutSeconds:)``
    /// and
    /// ``OZTransactionOperations/waitForContractVisibleToRpc(contractId:pollIntervalMs:timeoutSeconds:)``.
    public static let rpcVisibilityTimeoutSeconds: Int = 45

    /// Default timeout for transaction submission and polling in seconds.
    public static let defaultTimeoutSeconds: Int = 30

    /// Maximum signers per context rule (OpenZeppelin contract limit).
    public static let maxSigners: Int = 15

    /// Maximum policies per context rule (OpenZeppelin contract limit).
    public static let maxPolicies: Int = 5

    /// HTTP header name identifying the SDK name in indexer and relayer requests.
    public static let clientNameHeader: String = "X-Client-Name"

    /// HTTP header name identifying the SDK version in indexer and relayer requests.
    public static let clientVersionHeader: String = "X-Client-Version"

    /// SDK identifier value for the iOS Stellar SDK, sent in client identification headers.
    public static let clientName: String = "ios-stellar-sdk"

    /// Maximum size in bytes for indexer HTTP response bodies (1 MiB).
    ///
    /// `URLSession.data(for:)` buffers the entire response into memory before
    /// returning; capping the accepted size protects the SDK process from a
    /// compromised remote service returning an arbitrarily large body. The
    /// indexer's largest documented response shape (a contract-details payload
    /// with hundreds of context rules) fits comfortably under this limit.
    public static let maxIndexerResponseBytes: Int = 1 * 1024 * 1024

    /// Maximum size in bytes for relayer HTTP response bodies (256 KiB).
    ///
    /// Relayer responses carry at most a transaction hash plus a short status
    /// or error message; any larger payload is treated as a protocol failure
    /// and surfaces as `OZRelayerResponse(success: false, ...)`.
    public static let maxRelayerResponseBytes: Int = 256 * 1024
}
