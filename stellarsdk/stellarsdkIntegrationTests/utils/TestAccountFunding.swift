//
//  TestAccountFunding.swift
//  stellarsdkIntegrationTests
//
//  Created by Soneso on 11.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation
import stellarsdk

enum TestAccountFundingError: Error, CustomStringConvertible {
    case noEndpointProvided
    case notConsistentlyVisible(message: String)

    var description: String {
        switch self {
        case .noEndpointProvided:
            return "Provide at least one of horizon and rpc"
        case .notConsistentlyVisible(let message):
            return message
        }
    }
}

/// Funds the account via friendbot and polls until every provided endpoint
/// serves the account in `requiredConsecutiveSuccesses` consecutive rounds.
///
/// A single successful read is not enough on a load-balanced deployment:
/// later reads can hit replicas whose ingestion lags the one that answered
/// first, so a test read right after this helper would still miss the
/// account. Requiring consecutive rounds keeps polling until the account is
/// served consistently.
///
/// A friendbot failure is not fatal on its own: the account may already be
/// funded or the request rate limited, and only the visibility poll can
/// tell. Funding is attempted up to `fundingAttempts` times while the
/// account stays invisible; the helper throws only when the account is not
/// consistently visible when `timeout` has elapsed.
///
/// Pass the endpoints the test reads the account from: `horizon`, `rpc`, or
/// both. At least one must be provided. The poll and the test's subsequent
/// operations must use the same instance where one exists, otherwise the
/// same endpoint URL: pass the `StellarSDK` the test reads and submits
/// through, and the `SorobanServer` the test uses directly, or a server on
/// the URL the test hands to its client options.
func fundTestAccountAndAwaitVisibility(
    accountId: String,
    horizon: StellarSDK? = nil,
    rpc: SorobanServer? = nil,
    useFuturenet: Bool = false,
    pollInterval: TimeInterval = 2,
    confirmationInterval: TimeInterval = 1,
    requiredConsecutiveSuccesses: Int = 3,
    timeout: TimeInterval = 90,
    fundingAttempts: Int = 3,
    fundingRetryDelay: TimeInterval = 5
) async throws {
    guard horizon != nil || rpc != nil else {
        throw TestAccountFundingError.noEndpointProvided
    }

    // The friendbot URLs are fixed inside the account service, so any
    // instance funds correctly; the provided endpoints are what matters
    // for the visibility poll.
    let fundingSdk = horizon ?? (useFuturenet ? StellarSDK.futureNet() : StellarSDK.testNet())

    func fund() async -> Bool {
        let result = useFuturenet
            ? await fundingSdk.accounts.createFutureNetTestAccount(accountId: accountId)
            : await fundingSdk.accounts.createTestAccount(accountId: accountId)
        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    var rpcVisible = rpc == nil
    var horizonVisible = horizon == nil

    func visibleEverywhere() async -> Bool {
        if let rpc = rpc {
            let response = await rpc.getAccount(accountId: accountId)
            if case .success = response {
                rpcVisible = true
            } else {
                rpcVisible = false
            }
        }
        if let horizon = horizon {
            let response = await horizon.accounts.getAccountDetails(accountId: accountId)
            if case .success = response {
                horizonVisible = true
            } else {
                horizonVisible = false
            }
        }
        return rpcVisible && horizonVisible
    }

    func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    var funded = await fund()
    for _ in 1..<max(fundingAttempts, 1) {
        if funded {
            break
        }
        if await visibleEverywhere() {
            break
        }
        try await sleep(seconds: fundingRetryDelay)
        funded = await fund()
    }

    let deadline = Date().addingTimeInterval(timeout)
    var consecutiveSuccesses = 0
    while true {
        if await visibleEverywhere() {
            consecutiveSuccesses += 1
            if consecutiveSuccesses >= requiredConsecutiveSuccesses {
                return
            }
            try await sleep(seconds: confirmationInterval)
            continue
        }
        consecutiveSuccesses = 0
        if Date() > deadline {
            var endpoints: [String] = []
            if rpc != nil {
                endpoints.append("rpc visible: \(rpcVisible)")
            }
            if horizon != nil {
                endpoints.append("horizon visible: \(horizonVisible)")
            }
            throw TestAccountFundingError.notConsistentlyVisible(
                message: "Account \(accountId) is not consistently visible after "
                    + "friendbot funding (friendbot success: \(funded), "
                    + "\(endpoints.joined(separator: ", ")), "
                    + "visibility window of \(Int(timeout)) seconds elapsed)")
        }
        try await sleep(seconds: pollInterval)
    }
}
