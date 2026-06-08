//
//  MockOZTransactionOperations.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
@testable import stellarsdk

/// Recording test fixture mirroring the public surface of
/// ``OZTransactionOperations``.
///
/// `OZTransactionOperations` is declared `final`, so it cannot be subclassed.
/// Tests that need to assert the arguments produced by manager methods and
/// fed into the transaction-operations layer use this fixture as a stand-alone
/// recording surface. It is not directly substituted into
/// ``MockOZSmartAccountKit`` (the kit-protocol `transactionOperations`
/// property is typed as the concrete `OZTransactionOperations`); instead the
/// fixture is exposed for tests that drive the manager methods through their
/// internal builders and verify the resulting host functions and arguments
/// against the recorded calls supplied here.
///
/// All methods are non-throwing and return canned values; tests configure
/// the canned values per call site by setting the corresponding
/// `result*` property before invoking the manager under test.
final class MockOZTransactionOperations: @unchecked Sendable {

    // MARK: - Captured invocations

    /// A single captured `submit` invocation.
    struct SubmitCall {

        /// Host function passed to `submit`.
        let hostFunction: HostFunctionXDR

        /// Pre-existing authorization entries supplied by the caller.
        let auth: [SorobanAuthorizationEntryXDR]

        /// Submission-method override, if any.
        let forceMethod: OZSubmissionMethod?

        /// Whether a custom `resolveContextRuleIds` callback was supplied.
        let resolveContextRuleIdsProvided: Bool
    }

    /// A single captured `transfer` invocation.
    struct TransferCall {
        let tokenContract: String
        let recipient: String
        let amount: String
        let forceMethod: OZSubmissionMethod?
    }

    /// A single captured `contractCall` invocation.
    struct ContractCallCall {
        let target: String
        let targetFn: String
        let targetArgs: [SCValXDR]
        let forceMethod: OZSubmissionMethod?
        let resolveContextRuleIdsProvided: Bool
    }

    /// A single captured `executeAndSubmit` invocation.
    struct ExecuteAndSubmitCall {
        let target: String
        let targetFn: String
        let targetArgs: [SCValXDR]
        let forceMethod: OZSubmissionMethod?
        let resolveContextRuleIdsProvided: Bool
    }

    /// A single captured `fundWallet` invocation.
    struct FundWalletCall {
        let nativeTokenContract: String
        let forceMethod: OZSubmissionMethod?
    }

    /// A single captured `simulateAndExtractResult` invocation.
    struct SimulateAndExtractResultCall {
        let hostFunction: HostFunctionXDR
    }

    // MARK: - Recorded calls

    private let queue = DispatchQueue(label: "MockOZTransactionOperations.state")

    private var _submitCalls: [SubmitCall] = []
    private var _transferCalls: [TransferCall] = []
    private var _contractCallCalls: [ContractCallCall] = []
    private var _executeAndSubmitCalls: [ExecuteAndSubmitCall] = []
    private var _fundWalletCalls: [FundWalletCall] = []
    private var _simulateAndExtractResultCalls: [SimulateAndExtractResultCall] = []

    /// Recorded `submit` invocations in invocation order.
    var submitCalls: [SubmitCall] {
        return queue.sync { _submitCalls }
    }

    /// Recorded `transfer` invocations in invocation order.
    var transferCalls: [TransferCall] {
        return queue.sync { _transferCalls }
    }

    /// Recorded `contractCall` invocations in invocation order.
    var contractCallCalls: [ContractCallCall] {
        return queue.sync { _contractCallCalls }
    }

    /// Recorded `executeAndSubmit` invocations in invocation order.
    var executeAndSubmitCalls: [ExecuteAndSubmitCall] {
        return queue.sync { _executeAndSubmitCalls }
    }

    /// Recorded `fundWallet` invocations in invocation order.
    var fundWalletCalls: [FundWalletCall] {
        return queue.sync { _fundWalletCalls }
    }

    /// Recorded `simulateAndExtractResult` invocations in invocation order.
    var simulateAndExtractResultCalls: [SimulateAndExtractResultCall] {
        return queue.sync { _simulateAndExtractResultCalls }
    }

    // MARK: - Canned results

    /// Canned ``OZTransactionResult`` returned from every `submit`-family call
    /// when no per-test override is configured. Defaults to a deterministic
    /// success.
    var defaultResult = OZTransactionResult(success: true, hash: "deadbeef")

    /// Optional per-call result queue. When non-empty, each `submit`-family
    /// invocation pops the head of this queue instead of returning
    /// ``defaultResult``. Tests use this to script multiple sequential
    /// outcomes.
    var queuedResults: [OZTransactionResult] = []

    /// Canned amount string returned from `fundWallet`.
    var fundWalletResult: String = "0"

    /// Canned `SCValXDR` returned from `simulateAndExtractResult`. Defaults to
    /// `void`.
    var simulateAndExtractResultValue: SCValXDR = .void

    /// Optional thrown error for `submit`-family calls.
    var throwOnSubmit: Error?

    /// Optional thrown error for `simulateAndExtractResult`.
    var throwOnSimulateAndExtractResult: Error?

    /// Optional thrown error for `fundWallet`.
    var throwOnFundWallet: Error?

    // MARK: - Public mock surface

    /// Mock counterpart to ``OZTransactionOperations/submit(hostFunction:auth:forceMethod:resolveContextRuleIds:)``.
    func submit(
        hostFunction: HostFunctionXDR,
        auth: [SorobanAuthorizationEntryXDR],
        forceMethod: OZSubmissionMethod? = nil,
        resolveContextRuleIds: OZResolveContextRuleIds? = nil
    ) async throws -> OZTransactionResult {
        let call = SubmitCall(
            hostFunction: hostFunction,
            auth: auth,
            forceMethod: forceMethod,
            resolveContextRuleIdsProvided: resolveContextRuleIds != nil
        )
        return try queue.sync { () -> OZTransactionResult in
            _submitCalls.append(call)
            if let error = throwOnSubmit { throw error }
            if !queuedResults.isEmpty {
                return queuedResults.removeFirst()
            }
            return defaultResult
        }
    }

    /// Mock counterpart to ``OZTransactionOperations/transfer(tokenContract:recipient:amount:forceMethod:)``.
    func transfer(
        tokenContract: String,
        recipient: String,
        amount: String,
        forceMethod: OZSubmissionMethod? = nil
    ) async throws -> OZTransactionResult {
        let call = TransferCall(
            tokenContract: tokenContract,
            recipient: recipient,
            amount: amount,
            forceMethod: forceMethod
        )
        return try queue.sync { () -> OZTransactionResult in
            _transferCalls.append(call)
            if let error = throwOnSubmit { throw error }
            if !queuedResults.isEmpty {
                return queuedResults.removeFirst()
            }
            return defaultResult
        }
    }

    /// Mock counterpart to ``OZTransactionOperations/contractCall(target:targetFn:targetArgs:forceMethod:resolveContextRuleIds:)``.
    func contractCall(
        target: String,
        targetFn: String,
        targetArgs: [SCValXDR] = [],
        forceMethod: OZSubmissionMethod? = nil,
        resolveContextRuleIds: OZResolveContextRuleIds? = nil
    ) async throws -> OZTransactionResult {
        let call = ContractCallCall(
            target: target,
            targetFn: targetFn,
            targetArgs: targetArgs,
            forceMethod: forceMethod,
            resolveContextRuleIdsProvided: resolveContextRuleIds != nil
        )
        return try queue.sync { () -> OZTransactionResult in
            _contractCallCalls.append(call)
            if let error = throwOnSubmit { throw error }
            if !queuedResults.isEmpty {
                return queuedResults.removeFirst()
            }
            return defaultResult
        }
    }

    /// Mock counterpart to ``OZTransactionOperations/executeAndSubmit(target:targetFn:targetArgs:forceMethod:resolveContextRuleIds:)``.
    func executeAndSubmit(
        target: String,
        targetFn: String,
        targetArgs: [SCValXDR] = [],
        forceMethod: OZSubmissionMethod? = nil,
        resolveContextRuleIds: OZResolveContextRuleIds? = nil
    ) async throws -> OZTransactionResult {
        let call = ExecuteAndSubmitCall(
            target: target,
            targetFn: targetFn,
            targetArgs: targetArgs,
            forceMethod: forceMethod,
            resolveContextRuleIdsProvided: resolveContextRuleIds != nil
        )
        return try queue.sync { () -> OZTransactionResult in
            _executeAndSubmitCalls.append(call)
            if let error = throwOnSubmit { throw error }
            if !queuedResults.isEmpty {
                return queuedResults.removeFirst()
            }
            return defaultResult
        }
    }

    /// Mock counterpart to ``OZTransactionOperations/fundWallet(nativeTokenContract:forceMethod:)``.
    func fundWallet(
        nativeTokenContract: String,
        forceMethod: OZSubmissionMethod? = nil
    ) async throws -> String {
        let call = FundWalletCall(
            nativeTokenContract: nativeTokenContract,
            forceMethod: forceMethod
        )
        return try queue.sync { () -> String in
            _fundWalletCalls.append(call)
            if let error = throwOnFundWallet { throw error }
            return fundWalletResult
        }
    }

    /// Mock counterpart to the internal `simulateAndExtractResult` helper.
    func simulateAndExtractResult(
        hostFunction: HostFunctionXDR
    ) async throws -> SCValXDR {
        let call = SimulateAndExtractResultCall(hostFunction: hostFunction)
        return try queue.sync { () -> SCValXDR in
            _simulateAndExtractResultCalls.append(call)
            if let error = throwOnSimulateAndExtractResult { throw error }
            return simulateAndExtractResultValue
        }
    }

    /// Resets every recorded invocation list. Useful between assertion blocks
    /// inside the same test.
    func reset() {
        queue.sync {
            _submitCalls.removeAll()
            _transferCalls.removeAll()
            _contractCallCalls.removeAll()
            _executeAndSubmitCalls.removeAll()
            _fundWalletCalls.removeAll()
            _simulateAndExtractResultCalls.removeAll()
        }
    }
}
