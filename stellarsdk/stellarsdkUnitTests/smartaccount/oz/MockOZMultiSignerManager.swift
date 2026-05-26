//
//  MockOZMultiSignerManager.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
@testable import stellarsdk

/// Recording test double subclassing ``OZMultiSignerManager``.
///
/// Sibling smart-account managers call
/// ``OZSmartAccountKitProtocol/multiSignerManager`` directly when a non-empty
/// `selectedSigners` list is supplied. To observe that routing without
/// exercising the real signing pipeline, tests install this fixture on the
/// kit's ``MockOZSmartAccountKit/multiSignerManagerOverride`` slot; the
/// override is returned in place of the lazily-constructed real manager so
/// every sibling-manager submission flows through this recorder.
///
/// Use the ``invocations`` array to assert what was forwarded to the
/// three-argument
/// ``submitWithMultipleSigners(hostFunction:selectedSigners:forceMethod:)``
/// overload (the one sibling managers consume). The fixture returns
/// ``defaultResult`` from every call unless a per-test override is enqueued
/// via ``queuedResults`` or ``throwOnSubmit`` is set.
final class MockOZMultiSignerManager: OZMultiSignerManager, @unchecked Sendable {

    /// Snapshot of a single captured `submitWithMultipleSigners` call.
    struct Invocation {

        /// Host function passed by the caller.
        let hostFunction: HostFunctionXDR

        /// Selected signers passed by the caller.
        let selectedSigners: [SelectedSigner]

        /// Submission-method override, if any.
        let forceMethod: SubmissionMethod?
    }

    private let queue = DispatchQueue(label: "MockOZMultiSignerManager.state")
    private var _invocations: [Invocation] = []

    /// Captured invocations in invocation order.
    var invocations: [Invocation] {
        return queue.sync { _invocations }
    }

    /// Canned result returned from every `submitWithMultipleSigners` call when
    /// no per-call override is enqueued.
    var defaultResult: TransactionResult = TransactionResult(
        success: true,
        hash: "deadbeef"
    )

    /// Optional FIFO queue of canned results consulted before
    /// ``defaultResult``. Tests use this to script multiple sequential
    /// outcomes in cross-manager flow scenarios.
    var queuedResults: [TransactionResult] = []

    /// Optional thrown error for `submitWithMultipleSigners`. Lets tests
    /// exercise error-propagation paths without staging a real transaction
    /// failure.
    var throwOnSubmit: Error?

    /// Recording override of the three-argument sibling-manager entry point.
    ///
    /// Captures the call and returns the next canned result (or the default
    /// when the queue is empty). The four-argument
    /// ``OZMultiSignerManager/submitWithMultipleSigners(hostFunction:selectedSigners:forceMethod:resolveContextRuleIds:)``
    /// is left to the real implementation so direct unit tests of the
    /// multi-signer pipeline are not affected by this fixture.
    override func submitWithMultipleSigners(
        hostFunction: HostFunctionXDR,
        selectedSigners: [SelectedSigner],
        forceMethod: SubmissionMethod?
    ) async throws -> TransactionResult {
        let invocation = Invocation(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
        return try queue.sync { () -> TransactionResult in
            _invocations.append(invocation)
            if let error = throwOnSubmit { throw error }
            if !queuedResults.isEmpty {
                return queuedResults.removeFirst()
            }
            return defaultResult
        }
    }

    /// Clears every recorded invocation. Useful between assertion blocks in
    /// the same test.
    func reset() {
        queue.sync {
            _invocations.removeAll()
        }
    }
}
