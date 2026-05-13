//
//  OZSubmissionRouter.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// ============================================================================
// MARK: - OZSubmissionRouter
// ============================================================================

/// Internal helper that lifts the host-function submission routing logic out
/// of the individual smart-account managers.
///
/// Every state-changing manager method ends with the same decision: if the
/// caller supplied an empty `selectedSigners` list, submit through the kit's
/// transaction operations on the single-signer path; otherwise delegate to the
/// installed ``OZMultiSignerSubmitting`` collaborator. The three sibling
/// managers (``OZSignerManager``, ``OZPolicyManager``, ``OZContextRuleManager``)
/// previously each carried a verbatim copy of the routing logic. Centralising
/// it here keeps the routing contract single-source-of-truth and removes the
/// risk of drift when a fourth manager is added (or the existing routing
/// contract is extended with, for example, a per-manager fee override).
///
/// The router is intentionally a plain `enum` namespace with a single static
/// method; no per-manager state is captured, so an instance allocation per
/// call would be wasted.
internal enum OZSubmissionRouter {

    /// Routes a host-function submission to either the single-signer or the
    /// multi-signer code path based on the supplied `selectedSigners` list.
    ///
    /// - Parameters:
    ///   - hostFunction: The host function to submit.
    ///   - selectedSigners: Multi-signer participants. Empty selects
    ///     single-signer routing.
    ///   - forceMethod: Optional submission-method override.
    ///   - kit: The smart-account kit whose transaction operations handle
    ///     the single-signer path.
    ///   - multiSignerSubmitter: Optional collaborator consulted on the
    ///     multi-signer path. When `nil` and `selectedSigners` is non-empty,
    ///     the router throws ``ConfigurationException/InvalidConfig`` so the
    ///     caller can correct the kit composition rather than receiving a
    ///     confusing routing failure deeper in the pipeline.
    ///   - managerName: Human-readable manager name used to compose the
    ///     misconfiguration error message (for example `"policy manager"`).
    /// - Returns: The on-chain submission outcome.
    /// - Throws: ``TransactionException``, ``WalletException``,
    ///   ``ConfigurationException``.
    static func route(
        hostFunction: HostFunctionXDR,
        selectedSigners: [SelectedSigner],
        forceMethod: SubmissionMethod?,
        kit: OZSmartAccountKitProtocol,
        multiSignerSubmitter: OZMultiSignerSubmitting?,
        managerName: String
    ) async throws -> TransactionResult {
        if selectedSigners.isEmpty {
            return try await kit.transactionOperations.submit(
                hostFunction: hostFunction,
                auth: [],
                forceMethod: forceMethod
            )
        }

        guard let submitter = multiSignerSubmitter else {
            // why: in production the kit always installs the multi-signer
            // submitter at construction time. Reaching this branch means a
            // unit-test or alternate kit composition wired the manager
            // without a multi-signer collaborator yet still asked for
            // multi-signer routing — surface this as a configuration error
            // so the caller can correct the kit composition.
            throw ConfigurationException.invalidConfig(
                details: "Multi-signer routing requested but no multi-signer submitter is wired into the \(managerName)"
            )
        }

        return try await submitter.submitWithMultipleSigners(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }
}
