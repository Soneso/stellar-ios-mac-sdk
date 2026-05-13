//
//  OZSmartAccountKit+Wiring.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// ============================================================================
// MARK: - OZContextRuleManager + OZContextRuleParser
// ============================================================================

/// Cross-manager wiring that binds ``OZContextRuleManager`` into the
/// ``OZContextRuleParser`` protocol consumed by ``OZSignerManager`` for the
/// value-based ``OZSignerManager/removeSignerBySigner(contextRuleId:signer:selectedSigners:forceMethod:)``
/// path.
///
/// The two declarations carry slightly different argument-label shapes (the
/// context-rule manager exposes `getContextRule(id:)` and
/// `parseContextRule(scVal:)` with named parameters; the parser protocol uses
/// `getContextRule(contextRuleId:)` and `parseContextRule(_:)` with the second
/// argument unlabelled). Bridging the two through a thin adapter keeps both
/// surfaces idiomatic at their respective call sites without forcing either
/// side to drift toward the other.
///
/// The adapter forwards directly to the existing implementations on the
/// concrete manager and adds no behaviour of its own. It is declared in this
/// composition-root file rather than on `OZContextRuleManager` itself to keep
/// the manager source free of cross-cutting wiring concerns.
extension OZContextRuleManager: OZContextRuleParser {

    /// ``OZContextRuleParser`` conformance — forwards to
    /// ``OZContextRuleManager/getContextRule(id:)``.
    ///
    /// - Parameter contextRuleId: The context-rule identifier to look up.
    /// - Returns: The raw `SCValXDR` payload returned by the contract.
    /// - Throws: ``WalletException/NotConnected``, ``TransactionException``.
    internal func getContextRule(contextRuleId: UInt32) async throws -> SCValXDR {
        return try await self.getContextRule(id: contextRuleId)
    }

    /// ``OZContextRuleParser`` conformance — forwards to
    /// ``OZContextRuleManager/parseContextRule(scVal:)``.
    ///
    /// - Parameter scVal: The raw `SCValXDR` payload returned by the contract.
    /// - Returns: A parsed view of the rule.
    /// - Throws: ``ValidationException`` when the payload is malformed.
    internal func parseContextRule(_ scVal: SCValXDR) throws -> ParsedContextRule {
        return try self.parseContextRule(scVal: scVal)
    }
}
